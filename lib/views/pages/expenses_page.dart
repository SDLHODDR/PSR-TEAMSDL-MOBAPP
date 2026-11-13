import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/expenses_data.dart';
import '../../services/expenses_service.dart';

class ExpensesPage extends StatefulWidget {
  const ExpensesPage({super.key});

  @override
  State<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends State<ExpensesPage> {
  final ExpensesService service = ExpensesService();
  int monthIndex = 0;
  late Future<ExpensesData> expenses;

  @override
  void initState() {
    super.initState();
    expenses = service.load();
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
          if (monthIndex >= months.length) {
            monthIndex = 0;
          }
          final month = months[monthIndex];
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
                          for (var i = 0; i < months.length; i++)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(months[i].label),
                                selected: i == monthIndex,
                                onSelected: (_) =>
                                    setState(() => monthIndex = i),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Add expense',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ExpenseFormPage()),
                    ),
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
                items[i].remark.isEmpty ? 'Expense entry' : items[i].remark,
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
  const ExpenseFormPage({super.key});

  @override
  State<ExpenseFormPage> createState() => _ExpenseFormPageState();
}

class _ExpenseFormPageState extends State<ExpenseFormPage> {
  String? date;
  String? expenseName;
  final amount = TextEditingController();
  final remark = TextEditingController();

  static const dates = [
    '24-Sep-2026',
    '25-Sep-2026',
    '26-Sep-2026',
    '27-Sep-2026',
    '28-Sep-2026',
    '29-Sep-2026'
  ];
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
  void dispose() {
    amount.dispose();
    remark.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Daily Expenses (Sep-2026)')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _fieldLabel('Date'),
            DropdownButtonFormField<String>(
                value: date,
                items: [
                  for (final item in dates)
                    DropdownMenuItem(value: item, child: Text(item))
                ],
                onChanged: (value) => setState(() => date = value)),
            const SizedBox(height: 14),
            _fieldLabel('Expense Name'),
            DropdownButtonFormField<String>(
                value: expenseName,
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
                Navigator.pop(context);
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
