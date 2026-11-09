import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../services/mock_data_service.dart';

class ExpensesPage extends StatefulWidget {
  const ExpensesPage({super.key});

  @override
  State<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends State<ExpensesPage> {
  final MockDataService service = MockDataService();
  int monthIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Expenses')),
      body: FutureBuilder<dynamic>(
        future: service.read('expenses.json'),
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return const Center(child: Text('Unable to load expenses.'));
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final months = (snapshot.data['months'] as List).cast<Map>();
          final month = months[monthIndex];
          final items = (month['items'] as List).cast<Map>();
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
                                label: Text('${months[i]['label']}'),
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
              const SizedBox(height: 12),
              if (items.isEmpty)
                _EmptyExpenseState(status: '${month['status']}')
              else
                _ExpenseTable(
                    items: items,
                    total: (month['total'] as num).toDouble(),
                    status: '${month['status']}'),
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
  final List<Map> items;
  final double total;
  final String status;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Card(
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 24,
              columns: const [
                DataColumn(label: Text('#')),
                DataColumn(label: Text('Exp Type')),
                DataColumn(label: Text('Amount')),
                DataColumn(label: Text('Remarks')),
              ],
              rows: [
                for (var i = 0; i < items.length; i++)
                  DataRow(cells: [
                    DataCell(Text('${i + 1}')),
                    DataCell(Text('${items[i]['type']}')),
                    DataCell(
                        Text((items[i]['amount'] as num).toStringAsFixed(2))),
                    DataCell(Text('${items[i]['remark']}')),
                  ]),
                DataRow(cells: [
                  const DataCell(Text('')),
                  const DataCell(Text('Total',
                      style: TextStyle(fontWeight: FontWeight.bold))),
                  DataCell(Text(total.toStringAsFixed(2),
                      style: const TextStyle(fontWeight: FontWeight.bold))),
                  const DataCell(Text('')),
                ]),
              ],
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
