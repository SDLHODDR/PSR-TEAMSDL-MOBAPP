class ExpenseItem {
  const ExpenseItem({
    required this.type,
    required this.amount,
    required this.remark,
  });

  final String type;
  final double amount;
  final String remark;

  factory ExpenseItem.fromJson(Map<String, dynamic> json) {
    final type = json['type']?.toString().trim() ?? '';
    final amount = _number(json['amount']);
    if (type.isEmpty || amount == null) {
      throw const FormatException('Invalid expense item.');
    }
    return ExpenseItem(
      type: type,
      amount: amount,
      remark: json['remark']?.toString() ?? '',
    );
  }
}

class ExpenseMonth {
  const ExpenseMonth({
    required this.month,
    required this.label,
    required this.status,
    required this.total,
    required this.items,
  });

  final String month;
  final String label;
  final String status;
  final double total;
  final List<ExpenseItem> items;

  factory ExpenseMonth.fromJson(Map<String, dynamic> json) {
    final month = json['month']?.toString().trim() ?? '';
    final label = json['label']?.toString().trim() ?? '';
    final status = json['status']?.toString().trim() ?? '';
    final total = _number(json['total']);
    final itemsValue = json['items'];
    if (month.isEmpty ||
        label.isEmpty ||
        status.isEmpty ||
        total == null ||
        itemsValue is! List) {
      throw const FormatException('Invalid monthly expenses.');
    }

    return ExpenseMonth(
      month: month,
      label: label,
      status: status,
      total: total,
      items: itemsValue.map((value) {
        if (value is! Map) {
          throw const FormatException('Invalid expense item.');
        }
        return ExpenseItem.fromJson(Map<String, dynamic>.from(value));
      }).toList(growable: false),
    );
  }
}

class ExpensesData {
  const ExpensesData({required this.months});

  final List<ExpenseMonth> months;

  factory ExpensesData.fromJson(Map<String, dynamic> json) {
    final monthsValue = json['months'];
    if (monthsValue is! List) {
      throw const FormatException('Invalid expense months.');
    }
    return ExpensesData(
      months: monthsValue.map((value) {
        if (value is! Map) {
          throw const FormatException('Invalid monthly expenses.');
        }
        return ExpenseMonth.fromJson(Map<String, dynamic>.from(value));
      }).toList(growable: false),
    );
  }
}

double? _number(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '');
}
