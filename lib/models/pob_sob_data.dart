class PobSobOrder {
  const PobSobOrder({
    required this.customerId,
    required this.customer,
    required this.orderTo,
    required this.type,
    required this.amount,
    required this.status,
    required this.verifiedAt,
  });

  final int customerId;
  final String customer;
  final String orderTo;
  final String type;
  final double amount;
  final String status;
  final String verifiedAt;

  factory PobSobOrder.fromJson(Map<String, dynamic> json) {
    final customerId = _int(json['customer_id']);
    final customer = json['customer']?.toString().trim() ?? '';
    final type = json['type']?.toString().trim().toUpperCase() ?? '';
    final amount = _number(json['amount']);
    if (customerId == null ||
        customerId <= 0 ||
        customer.isEmpty ||
        (type != 'POB' && type != 'SOB') ||
        amount == null) {
      throw const FormatException('Invalid POB/SOB order.');
    }

    return PobSobOrder(
      customerId: customerId,
      customer: customer,
      orderTo: json['order_to']?.toString() ?? '',
      type: type,
      amount: amount,
      status: json['status']?.toString() ?? '',
      verifiedAt: json['verified_at']?.toString() ?? '',
    );
  }
}

class PobSobDay {
  const PobSobDay({
    required this.date,
    required this.day,
    required this.isFuture,
    required this.customerCount,
    required this.total,
    required this.pobTotal,
    required this.sobTotal,
    required this.orders,
  });

  final DateTime date;
  final int day;
  final bool isFuture;
  final int customerCount;
  final double total;
  final double pobTotal;
  final double sobTotal;
  final List<PobSobOrder> orders;

  factory PobSobDay.fromJson(Map<String, dynamic> json) {
    final date = DateTime.tryParse(json['date']?.toString() ?? '');
    final day = _int(json['day']);
    final customerCount = _int(json['customer_count']);
    final total = _number(json['total']);
    final pobTotal = _number(json['pob_total']);
    final sobTotal = _number(json['sob_total']);
    final ordersValue = json['orders'];
    if (date == null ||
        day == null ||
        customerCount == null ||
        total == null ||
        pobTotal == null ||
        sobTotal == null ||
        ordersValue is! List) {
      throw const FormatException('Invalid POB/SOB day.');
    }

    return PobSobDay(
      date: date,
      day: day,
      isFuture: json['is_future'] == true,
      customerCount: customerCount,
      total: total,
      pobTotal: pobTotal,
      sobTotal: sobTotal,
      orders: ordersValue.map((value) {
        if (value is! Map) {
          throw const FormatException('Invalid POB/SOB order.');
        }
        return PobSobOrder.fromJson(Map<String, dynamic>.from(value));
      }).toList(growable: false),
    );
  }
}

class PobSobMonth {
  const PobSobMonth({
    required this.month,
    required this.label,
    required this.days,
  });

  final String month;
  final String label;
  final List<PobSobDay> days;

  factory PobSobMonth.fromJson(Map<String, dynamic> json) {
    final month = json['month']?.toString().trim() ?? '';
    final label = json['label']?.toString().trim() ?? '';
    final daysValue = json['days'];
    if (month.isEmpty || label.isEmpty || daysValue is! List) {
      throw const FormatException('Invalid POB/SOB month.');
    }
    return PobSobMonth(
      month: month,
      label: label,
      days: daysValue.map((value) {
        if (value is! Map) {
          throw const FormatException('Invalid POB/SOB day.');
        }
        return PobSobDay.fromJson(Map<String, dynamic>.from(value));
      }).toList(growable: false),
    );
  }
}

int? _int(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

double? _number(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '');
}
