class PobSobOrder {
  const PobSobOrder({
    required this.orderId,
    required this.source,
    required this.customerId,
    required this.customer,
    required this.orderTo,
    required this.type,
    required this.amount,
    required this.status,
    required this.verifiedAt,
  });

  final int orderId;
  final String source;
  final int customerId;
  final String customer;
  final String orderTo;
  final String type;
  final double amount;
  final String status;
  final String verifiedAt;

  factory PobSobOrder.fromJson(Map<String, dynamic> json) {
    final orderId = _int(json['order_id']);
    final customerId = _int(json['customer_id']);
    final customer = json['customer']?.toString().trim() ?? '';
    final type = json['type']?.toString().trim().toUpperCase() ?? '';
    final source = json['source']?.toString().trim().toUpperCase() ?? '';
    final amount = _number(json['amount']);
    if (orderId == null ||
        orderId <= 0 ||
        !const ['PO', 'CP', 'CS'].contains(source) ||
        customerId == null ||
        customerId <= 0 ||
        customer.isEmpty ||
        (type != 'POB' && type != 'SOB') ||
        amount == null) {
      throw const FormatException('Invalid POB/SOB order.');
    }

    return PobSobOrder(
      orderId: orderId,
      source: source,
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

class PobSobCustomer {
  const PobSobCustomer({
    required this.id,
    required this.name,
    required this.code,
  });

  final int id;
  final String name;
  final String code;

  factory PobSobCustomer.fromJson(Map<String, dynamic> json) {
    final id = _int(json['customer_id']);
    final name = json['name']?.toString().trim() ?? '';
    if (id == null || id <= 0 || name.isEmpty) {
      throw const FormatException('Invalid POB/SOB customer.');
    }
    return PobSobCustomer(
      id: id,
      name: name,
      code: json['code']?.toString() ?? '',
    );
  }
}

class PobSobOrderTo {
  const PobSobOrderTo({required this.id, required this.name});

  final int id;
  final String name;

  factory PobSobOrderTo.fromJson(Map<String, dynamic> json) {
    final id = _int(json['id']);
    final name = json['name']?.toString().trim() ?? '';
    if (id == null || id <= 0 || name.isEmpty) {
      throw const FormatException('Invalid POB/SOB order-to option.');
    }
    return PobSobOrderTo(id: id, name: name);
  }
}

class PobSobProduct {
  const PobSobProduct({
    required this.id,
    required this.name,
    required this.category,
    required this.rate,
  });

  final int id;
  final String name;
  final String category;
  final double rate;

  factory PobSobProduct.fromJson(Map<String, dynamic> json) {
    final id = _int(json['product_id']);
    final name = json['name']?.toString().trim() ?? '';
    final rate = _number(json['rate']);
    if (id == null || id <= 0 || name.isEmpty || rate == null) {
      throw const FormatException('Invalid POB/SOB product.');
    }
    return PobSobProduct(
      id: id,
      name: name,
      category: json['category']?.toString() ?? '',
      rate: rate,
    );
  }
}

class PobSobOptions {
  const PobSobOptions({
    required this.date,
    required this.customers,
    required this.orderToOptions,
    required this.products,
  });

  final DateTime date;
  final List<PobSobCustomer> customers;
  final List<PobSobOrderTo> orderToOptions;
  final List<PobSobProduct> products;

  factory PobSobOptions.fromJson(Map<String, dynamic> json) {
    final date = DateTime.tryParse(json['date']?.toString() ?? '');
    final customers = json['customers'];
    final orderTo = json['order_to_options'];
    final products = json['products'];
    if (date == null ||
        customers is! List ||
        orderTo is! List ||
        products is! List) {
      throw const FormatException('Invalid POB/SOB options.');
    }
    return PobSobOptions(
      date: date,
      customers: customers.map((value) {
        if (value is! Map) {
          throw const FormatException('Invalid POB/SOB customer.');
        }
        return PobSobCustomer.fromJson(Map<String, dynamic>.from(value));
      }).toList(growable: false),
      orderToOptions: orderTo.map((value) {
        if (value is! Map) {
          throw const FormatException('Invalid POB/SOB order-to option.');
        }
        return PobSobOrderTo.fromJson(Map<String, dynamic>.from(value));
      }).toList(growable: false),
      products: products.map((value) {
        if (value is! Map) {
          throw const FormatException('Invalid POB/SOB product.');
        }
        return PobSobProduct.fromJson(Map<String, dynamic>.from(value));
      }).toList(growable: false),
    );
  }
}

class PobSobOrderLine {
  const PobSobOrderLine({
    required this.productId,
    required this.product,
    required this.category,
    required this.rate,
    required this.quantity,
    required this.freeQuantity,
    required this.amount,
  });

  final int productId;
  final String product;
  final String category;
  final double rate;
  final double quantity;
  final double freeQuantity;
  final double amount;

  factory PobSobOrderLine.fromJson(Map<String, dynamic> json) {
    final productId = _int(json['product_id']);
    final product = json['product']?.toString().trim() ?? '';
    final rate = _number(json['rate']);
    final quantity = _number(json['quantity']);
    final freeQuantity = _number(json['free_quantity']);
    final amount = _number(json['amount']);
    if (productId == null ||
        productId <= 0 ||
        product.isEmpty ||
        rate == null ||
        quantity == null ||
        freeQuantity == null ||
        amount == null) {
      throw const FormatException('Invalid POB/SOB order item.');
    }
    return PobSobOrderLine(
      productId: productId,
      product: product,
      category: json['category']?.toString().trim() ?? '',
      rate: rate,
      quantity: quantity,
      freeQuantity: freeQuantity,
      amount: amount,
    );
  }
}

class PobSobOrderDetails {
  const PobSobOrderDetails({
    required this.orderId,
    required this.source,
    required this.date,
    required this.dateLabel,
    required this.customerId,
    required this.customer,
    required this.customerCode,
    required this.orderToId,
    required this.orderTo,
    required this.type,
    required this.amount,
    required this.status,
    required this.processFlag,
    required this.verifiedAt,
    required this.employee,
    required this.canEdit,
    required this.items,
  });

  final int orderId;
  final String source;
  final DateTime date;
  final String dateLabel;
  final int customerId;
  final String customer;
  final String customerCode;
  final int orderToId;
  final String orderTo;
  final String type;
  final double amount;
  final String status;
  final String processFlag;
  final String verifiedAt;
  final String employee;
  final bool canEdit;
  final List<PobSobOrderLine> items;

  factory PobSobOrderDetails.fromJson(Map<String, dynamic> json) {
    final orderId = _int(json['order_id']);
    final date = DateTime.tryParse(json['date']?.toString() ?? '');
    final customerId = _int(json['customer_id']);
    final orderToId = _int(json['order_to_id']);
    final amount = _number(json['amount']);
    final type = json['type']?.toString().trim().toUpperCase() ?? '';
    final items = json['items'];
    if (orderId == null ||
        orderId <= 0 ||
        date == null ||
        customerId == null ||
        orderToId == null ||
        amount == null ||
        (type != 'POB' && type != 'SOB') ||
        items is! List) {
      throw const FormatException('Invalid POB/SOB order details.');
    }
    return PobSobOrderDetails(
      orderId: orderId,
      source: json['source']?.toString().toUpperCase() ?? '',
      date: date,
      dateLabel: json['date_label']?.toString() ?? '',
      customerId: customerId,
      customer: json['customer']?.toString() ?? '',
      customerCode: json['customer_code']?.toString() ?? '',
      orderToId: orderToId,
      orderTo: json['order_to']?.toString() ?? '',
      type: type,
      amount: amount,
      status: json['status']?.toString() ?? '',
      processFlag: json['process_flag']?.toString() ?? '',
      verifiedAt: json['verified_at']?.toString() ?? '',
      employee: json['employee']?.toString() ?? '',
      canEdit: json['can_edit'] == true,
      items: items.map((value) {
        if (value is! Map) {
          throw const FormatException('Invalid POB/SOB order item.');
        }
        return PobSobOrderLine.fromJson(Map<String, dynamic>.from(value));
      }).toList(growable: false),
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
