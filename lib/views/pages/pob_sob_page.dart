import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../models/pob_sob_data.dart';
import '../../providers/employee_provider.dart';
import '../../services/pob_sob_service.dart';

class PobSobPage extends StatefulWidget {
  const PobSobPage({super.key});

  @override
  State<PobSobPage> createState() => _PobSobPageState();
}

class _PobSobPageState extends State<PobSobPage> {
  final PobSobService service = PobSobService();
  late DateTime selectedMonth;
  late Future<PobSobMonth> monthData;
  DateTime? selectedDate;
  int tab = 0;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    selectedMonth = DateTime(now.year, now.month);
    monthData = _loadMonth(selectedMonth);
  }

  Future<PobSobMonth> _loadMonth(DateTime month) async {
    final data = await service.loadMonth(month);
    if (selectedDate == null || !_sameMonth(selectedDate!, month)) {
      final today = DateTime.now();
      final hasToday = _sameMonth(today, month);
      final firstWithOrders = data.days.cast<PobSobDay?>().firstWhere(
            (day) => day!.orders.isNotEmpty,
            orElse: () => null,
          );
      selectedDate = hasToday
          ? DateTime(today.year, today.month, today.day)
          : firstWithOrders?.date ?? DateTime(month.year, month.month, 1);
    }
    return data;
  }

  void _changeMonth(int offset) {
    final nextMonth =
        DateTime(selectedMonth.year, selectedMonth.month + offset);
    setState(() {
      selectedMonth = nextMonth;
      selectedDate = null;
      monthData = _loadMonth(nextMonth);
    });
  }

  @override
  Widget build(BuildContext context) {
    final employee = context.watch<EmployeeProvider>().employee;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('POB / SOB Orders'),
            if (employee?.empCode != null)
              Text(
                employee!.empCode!,
                style: Theme.of(context).textTheme.labelSmall,
              ),
          ],
        ),
      ),
      body: FutureBuilder<PobSobMonth>(
        future: monthData,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _LoadError(
              message: snapshot.error is ApiException
                  ? (snapshot.error as ApiException).message
                  : 'Unable to load POB/SOB orders.',
              onRetry: () => setState(
                () => monthData = _loadMonth(selectedMonth),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;
          final selectedDay = data.days.firstWhere(
            (day) => selectedDate != null && _sameDate(day.date, selectedDate!),
            orElse: () => data.days.first,
          );
          final orders = selectedDay.orders
              .where((order) => order.type == (tab == 0 ? 'POB' : 'SOB'))
              .toList(growable: false);
          final customerCount =
              orders.map((order) => order.customerId).toSet().length;
          final monthlyTotal =
              tab == 0 ? _sumPob(data.days) : _sumSob(data.days);

          return LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 700;
              return ListView(
                padding:
                    EdgeInsets.fromLTRB(wide ? 24 : 16, 16, wide ? 24 : 16, 28),
                children: [
                  _MonthHeader(
                    label: data.label,
                    canGoNext: !_isCurrentMonth(selectedMonth),
                    onPrevious: () => _changeMonth(-1),
                    onNext: () => _changeMonth(1),
                  ),
                  const SizedBox(height: 16),
                  _OrderOverview(
                    type: tab == 0 ? 'POB' : 'SOB',
                    amount: monthlyTotal,
                    orderCount:
                        _orderCount(data.days, tab == 0 ? 'POB' : 'SOB'),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: SegmentedButton<int>(
                      segments: const [
                        ButtonSegment<int>(
                          value: 0,
                          label: Text('POB'),
                          icon: Icon(Icons.shopping_bag_outlined),
                        ),
                        ButtonSegment<int>(
                          value: 1,
                          label: Text('SOB'),
                          icon: Icon(Icons.store_outlined),
                        ),
                      ],
                      selected: {tab},
                      onSelectionChanged: (selection) =>
                          setState(() => tab = selection.first),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const _WeekHeader(),
                  _MonthCalendar(
                    month: selectedMonth,
                    days: data.days,
                    selectedDate: selectedDate ?? selectedDay.date,
                    onSelect: (date) => setState(() => selectedDate = date),
                  ),
                  const SizedBox(height: 18),
                  _SelectedDayHeader(
                    date: selectedDay.date,
                    type: tab == 0 ? 'POB' : 'SOB',
                    total:
                        tab == 0 ? selectedDay.pobTotal : selectedDay.sobTotal,
                    customerCount: customerCount,
                  ),
                  const SizedBox(height: 10),
                  if (orders.isEmpty)
                    const _EmptyOrders()
                  else
                    for (var index = 0; index < orders.length; index++)
                      _OrderCard(order: orders[index], index: index + 1),
                ],
              );
            },
          );
        },
      ),
    );
  }

  double _sumPob(List<PobSobDay> days) =>
      days.fold(0, (total, day) => total + day.pobTotal);

  double _sumSob(List<PobSobDay> days) =>
      days.fold(0, (total, day) => total + day.sobTotal);

  int _orderCount(List<PobSobDay> days, String type) => days.fold(
        0,
        (total, day) =>
            total + day.orders.where((order) => order.type == type).length,
      );
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({
    required this.label,
    required this.canGoNext,
    required this.onPrevious,
    required this.onNext,
  });

  final String label;
  final bool canGoNext;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          IconButton.filledTonal(
            tooltip: 'Previous month',
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton.filledTonal(
            tooltip: 'Next month',
            onPressed: canGoNext ? onNext : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      );
}

class _OrderOverview extends StatelessWidget {
  const _OrderOverview({
    required this.type,
    required this.amount,
    required this.orderCount,
  });

  final String type;
  final double amount;
  final int orderCount;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.navy, Color(0xFF176B87)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                type == 'POB'
                    ? Icons.shopping_bag_outlined
                    : Icons.store_outlined,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MONTHLY $type',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      letterSpacing: 1,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    '$orderCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'orders',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _WeekHeader extends StatelessWidget {
  const _WeekHeader();

  @override
  Widget build(BuildContext context) => Row(
        children: [
          for (final day in ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    day,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
}

class _MonthCalendar extends StatelessWidget {
  const _MonthCalendar({
    required this.month,
    required this.days,
    required this.selectedDate,
    required this.onSelect,
  });

  final DateTime month;
  final List<PobSobDay> days;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final offset = DateTime(month.year, month.month, 1).weekday - 1;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: offset + days.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisExtent: 53,
      ),
      itemBuilder: (context, index) {
        final dayIndex = index - offset;
        if (dayIndex < 0) return const SizedBox.shrink();
        final day = days[dayIndex];
        final selected = _sameDate(day.date, selectedDate);
        final hasOrders = day.customerCount > 0;
        return Padding(
          padding: const EdgeInsets.all(3),
          child: Material(
            color: selected
                ? AppColors.navy
                : hasOrders
                    ? AppColors.navy.withValues(alpha: 0.08)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(13),
            child: InkWell(
              onTap: day.isFuture ? null : () => onSelect(day.date),
              borderRadius: BorderRadius.circular(13),
              child: Opacity(
                opacity: day.isFuture ? 0.38 : 1,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${day.day}',
                      style: TextStyle(
                        color: selected ? Colors.white : AppColors.navy,
                        fontWeight:
                            selected || hasOrders ? FontWeight.bold : null,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: hasOrders
                            ? (selected ? AppColors.green : AppColors.navy)
                            : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SelectedDayHeader extends StatelessWidget {
  const _SelectedDayHeader({
    required this.date,
    required this.type,
    required this.total,
    required this.customerCount,
  });

  final DateTime date;
  final String type;
  final double total;
  final int customerCount;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${date.day} ${_monthName(date.month)} ${date.year}',
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$customerCount ${customerCount == 1 ? 'customer' : 'customers'} · $type',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '₹${total.toStringAsFixed(2)}',
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.index});

  final PobSobOrder order;
  final int index;

  @override
  Widget build(BuildContext context) {
    final isSob = order.type == 'SOB';
    return Card(
      margin: const EdgeInsets.only(bottom: 9),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        leading: CircleAvatar(
          backgroundColor: (isSob ? AppColors.green : AppColors.navy)
              .withValues(alpha: 0.12),
          foregroundColor: AppColors.navy,
          child: Text('$index',
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        title: Text(
          order.customer,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (order.orderTo.isNotEmpty) Text('Order to: ${order.orderTo}'),
            Text(
              _orderStatus(order),
              style: TextStyle(
                color: order.verifiedAt.isNotEmpty
                    ? Colors.green.shade700
                    : AppColors.muted,
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: Text(
          '₹${order.amount.toStringAsFixed(2)}',
          style: const TextStyle(
            color: AppColors.navy,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String _orderStatus(PobSobOrder order) {
    if (order.verifiedAt.isNotEmpty) return 'Verified · ${order.verifiedAt}';
    if (order.status == 'A') return 'Authorized';
    if (order.status == 'N') return 'Pending';
    return order.status.isEmpty ? 'Order recorded' : order.status;
  }
}

class _EmptyOrders extends StatelessWidget {
  const _EmptyOrders();

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            children: [
              Icon(
                Icons.event_busy_outlined,
                color: AppColors.muted.withValues(alpha: 0.75),
                size: 32,
              ),
              const SizedBox(height: 8),
              const Text(
                'No orders for this day',
                style: TextStyle(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      );
}

bool _sameDate(DateTime left, DateTime right) =>
    left.year == right.year &&
    left.month == right.month &&
    left.day == right.day;

bool _sameMonth(DateTime date, DateTime month) =>
    date.year == month.year && date.month == month.month;

bool _isCurrentMonth(DateTime month) => _sameMonth(month, DateTime.now());

String _monthName(int month) => const [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ][month - 1];
