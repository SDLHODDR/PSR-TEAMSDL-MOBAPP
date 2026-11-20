import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/expenses_data.dart';
import '../../services/expenses_service.dart';

class ExpensesPage extends StatefulWidget {
  const ExpensesPage({super.key, this.service});

  final ExpensesService? service;

  @override
  State<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends State<ExpensesPage> {
  late final ExpensesService service;
  String? selectedMonth;
  late Future<ExpensesData> expenses;

  @override
  void initState() {
    super.initState();
    service = widget.service ?? ExpensesService();
    expenses = service.load();
  }

  Future<void> _addExpense(ExpenseMonth month, String currentMonthKey) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ExpenseFormPage(
          month: month.month,
          monthLabel: month.label,
          isCurrentMonth: month.isCurrent || month.month == currentMonthKey,
        ),
      ),
    );
    if (saved == true && mounted) {
      setState(() => expenses = service.load());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Expenses')),
      body: FutureBuilder<ExpensesData>(
        future: expenses,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Unable to load expenses.'),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () =>
                          setState(() => expenses = service.load()),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final months = snapshot.data!.months;
          if (months.isEmpty) {
            return const Center(child: Text('No expense periods available.'));
          }
          final currentMonthKey = _monthKey(DateTime.now());
          final currentPeriods = months
              .where(
                  (month) => month.isCurrent || month.month == currentMonthKey)
              .toList(growable: false);
          if (currentPeriods.isEmpty) {
            return const Center(
              child: Text('The current expense period is unavailable.'),
            );
          }
          final currentPeriod = currentPeriods.first;
          final historicalMonths = months
              .where(
                  (month) => !month.isCurrent && month.month != currentMonthKey)
              .take(3)
              .toList(growable: false);
          final selectedPeriods = months
              .where((month) => month.month == selectedMonth)
              .toList(growable: false);
          final month = selectedMonth == null || selectedPeriods.isEmpty
              ? currentPeriod
              : selectedPeriods.first;
          final items = month.items;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
            children: [
              Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final period in historicalMonths)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(period.label),
                                selected: period.month == selectedMonth,
                                onSelected: (_) => setState(
                                  () => selectedMonth =
                                      selectedMonth == period.month
                                          ? null
                                          : period.month,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Add expense',
                    onPressed: () => _addExpense(month, currentMonthKey),
                    icon: const Icon(Icons.add_box, color: AppColors.navy),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _ExpenseMonthOverview(month: month),
              const SizedBox(height: 18),
              if (items.isEmpty)
                _EmptyExpenseState(status: month.status)
              else
                _ExpenseTable(
                    items: items, total: month.total, status: month.status),
            ],
          );
        },
      ),
    );
  }
}

class _ExpenseTable extends StatelessWidget {
  const _ExpenseTable(
      {required this.items, required this.total, required this.status});
  final List<ExpenseItem> items;
  final double total;
  final String status;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(4, 0, 4, 10),
          child: Text(
            'EXPENSE BREAKDOWN',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
        ),
        for (var i = 0; i < items.length; i++)
          Card(
            margin: const EdgeInsets.only(bottom: 9),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              leading: CircleAvatar(
                backgroundColor: AppColors.navy.withValues(alpha: 0.08),
                foregroundColor: AppColors.navy,
                child: Text('${i + 1}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              title: Text(
                items[i].type,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                items[i].remark.isEmpty ? 'Remarks' : items[i].remark,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Text(
                '₹${items[i].amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: AppColors.navy,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        if (status == 'draft') ...[
          const SizedBox(height: 18),
          FilledButton(onPressed: () {}, child: const Text('Submit')),
        ],
      ],
    );
  }
}

class _ExpenseMonthOverview extends StatelessWidget {
  const _ExpenseMonthOverview({required this.month});

  final ExpenseMonth month;

  @override
  Widget build(BuildContext context) {
    final (label, icon, color) = switch (month.status) {
      'submitted' => ('Submitted', Icons.check_circle_outline, AppColors.green),
      'draft' => ('Draft', Icons.edit_note, const Color(0xFFFFC857)),
      _ => ('Not submitted', Icons.pending_outlined, Colors.white70),
    };

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.navy, Color(0xFF176B87)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long, color: Colors.white70),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  month.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(icon, color: color, size: 19),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(color: color, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'MONTHLY TOTAL',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '₹${month.total.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 29,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${month.items.length} ${month.items.length == 1 ? 'entry' : 'entries'}',
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _EmptyExpenseState extends StatelessWidget {
  const _EmptyExpenseState({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              const Text('No expense entries for this month.'),
              if (status == 'notSubmitted') ...[
                const SizedBox(height: 10),
                const Text('Non reporting days: 02-Nov',
                    style: TextStyle(color: Colors.red)),
              ],
            ],
          ),
        ),
      );
}

class ExpenseFormPage extends StatefulWidget {
  const ExpenseFormPage({
    super.key,
    required this.month,
    required this.monthLabel,
    required this.isCurrentMonth,
  });

  final String month;
  final String monthLabel;
  final bool isCurrentMonth;

  @override
  State<ExpenseFormPage> createState() => _ExpenseFormPageState();
}

class _ExpenseFormPageState extends State<ExpenseFormPage> {
  String? date;
  String? expenseName;
  final amount = TextEditingController();
  final remark = TextEditingController();

  late final List<String> dates;
  static const expenseNames = [
    'Additional Expenses',
    'Banner Print',
    'Certificate print',
    'Courier Charges',
    'Fax',
    'Gift for Doctor',
    'Meeting Expense',
    'Telephone Expense'
  ];

  @override
  void initState() {
    super.initState();
    dates = _expenseDates(widget.month, widget.isCurrentMonth);
    if (widget.isCurrentMonth && dates.isNotEmpty) {
      date = dates.first;
    }
  }

  @override
  void dispose() {
    amount.dispose();
    remark.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text('Daily Expenses (${widget.monthLabel})')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _fieldLabel('Date'),
            DropdownButtonFormField<String>(
                initialValue: date,
                items: [
                  for (final item in dates)
                    DropdownMenuItem(value: item, child: Text(item))
                ],
                onChanged: (value) => setState(() => date = value)),
            const SizedBox(height: 14),
            _fieldLabel('Expense Name'),
            DropdownButtonFormField<String>(
                initialValue: expenseName,
                items: [
                  for (final item in expenseNames)
                    DropdownMenuItem(value: item, child: Text(item))
                ],
                onChanged: (value) => setState(() => expenseName = value)),
            const SizedBox(height: 14),
            _fieldLabel('Amount'),
            TextField(
                controller: amount,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'Enter amount')),
            const SizedBox(height: 14),
            _fieldLabel('Remark'),
            TextField(controller: remark, maxLines: 3),
            const SizedBox(height: 22),
            FilledButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Expense saved locally for demo.')));
                Navigator.pop(context, true);
              },
              style: FilledButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Save and Send For Authorisation'),
            ),
          ],
        ),
      );

  Widget _fieldLabel(String value) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(value,
            style: const TextStyle(
                color: AppColors.navy, fontWeight: FontWeight.bold)),
      );
}

String _monthKey(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}';

List<String> _expenseDates(String month, bool isCurrentMonth) {
  final firstOfMonth = DateTime.tryParse('$month-01');
  if (firstOfMonth == null || _monthKey(firstOfMonth) != month) {
    return const [];
  }

  final lastOfMonth = DateTime(firstOfMonth.year, firstOfMonth.month + 1, 0);
  if (isCurrentMonth) {
    final today = DateTime.now();
    final day = today.day.clamp(1, lastOfMonth.day);
    return [
      _formatExpenseDate(DateTime(firstOfMonth.year, firstOfMonth.month, day))
    ];
  }

  final firstSelectableDate = lastOfMonth.subtract(const Duration(days: 6));
  return List.generate(
    7,
    (index) => _formatExpenseDate(
      firstSelectableDate.add(Duration(days: index)),
    ),
  );
}

String _formatExpenseDate(DateTime date) {
  const monthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${date.day.toString().padLeft(2, '0')}-'
      '${monthNames[date.month - 1]}-${date.year}';
}
