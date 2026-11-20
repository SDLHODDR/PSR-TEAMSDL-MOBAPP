import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdl_psr_field_app/models/expenses_data.dart';
import 'package:sdl_psr_field_app/services/expenses_service.dart';
import 'package:sdl_psr_field_app/views/pages/expenses_page.dart';

void main() {
  testWidgets('shows the current month by default and adds for that month',
      (tester) async {
    final currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
    final months = _months(currentMonth);

    await tester.pumpWidget(
      MaterialApp(
        home: ExpensesPage(service: _FakeExpensesService(months)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(_monthLabel(currentMonth)), findsOneWidget);
    expect(find.text('Remarks'), findsOneWidget);
    expect(
      tester
          .widgetList<ChoiceChip>(find.byType(ChoiceChip))
          .every((chip) => !chip.selected),
      isTrue,
    );

    await tester.tap(find.byTooltip('Add expense'));
    await tester.pumpAndSettle();

    expect(find.text('Daily Expenses (${_monthLabel(currentMonth)})'),
        findsOneWidget);
    expect(find.text(_dateLabel(DateTime.now())), findsOneWidget);
  });

  testWidgets('uses the selected previous month for the expense form',
      (tester) async {
    final previousMonth =
        DateTime(DateTime.now().year, DateTime.now().month - 1);
    final months = _months(DateTime(DateTime.now().year, DateTime.now().month));

    await tester.pumpWidget(
      MaterialApp(
        home: ExpensesPage(service: _FakeExpensesService(months)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(_monthLabel(previousMonth)));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Add expense'));
    await tester.pumpAndSettle();

    expect(find.text('Daily Expenses (${_monthLabel(previousMonth)})'),
        findsOneWidget);

    final lastDay = DateTime(previousMonth.year, previousMonth.month + 1, 0);
    final firstSelectableDay = lastDay.subtract(const Duration(days: 6));
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    expect(find.text(_dateLabel(firstSelectableDay)), findsOneWidget);
    expect(find.text(_dateLabel(lastDay)), findsOneWidget);
  });
}

List<ExpenseMonth> _months(DateTime currentMonth) => [
      for (var offset = 0; offset < 4; offset++)
        _month(DateTime(currentMonth.year, currentMonth.month - offset),
            isCurrent: offset == 0),
    ];

ExpenseMonth _month(DateTime date, {required bool isCurrent}) => ExpenseMonth(
      month: '${date.year}-${date.month.toString().padLeft(2, '0')}',
      label: _monthLabel(date),
      status: 'notSubmitted',
      total: isCurrent ? 50 : 0,
      items: isCurrent
          ? const [
              ExpenseItem(type: 'HQ Allowance', amount: 50, remark: ''),
            ]
          : const [],
      isCurrent: isCurrent,
    );

String _monthLabel(DateTime date) => '${_shortMonth(date.month)}-${date.year}';

String _dateLabel(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}-${_shortMonth(date.month)}-${date.year}';

String _shortMonth(int month) => const [
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
    ][month - 1];

class _FakeExpensesService extends ExpensesService {
  _FakeExpensesService(this.months);

  final List<ExpenseMonth> months;

  @override
  Future<ExpensesData> load() async => ExpensesData(months: months);
}
