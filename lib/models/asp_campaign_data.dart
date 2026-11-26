class AspCampaignOrder {
  const AspCampaignOrder({
    required this.orderId,
    required this.customer,
    required this.orderTo,
    required this.date,
    required this.amount,
    required this.status,
    required this.processFlag,
    required this.invoiceCount,
  });

  final int orderId;
  final String customer;
  final String orderTo;
  final String date;
  final double amount;
  final String status;
  final String processFlag;
  final int invoiceCount;

  factory AspCampaignOrder.fromJson(Map<String, dynamic> json) =>
      AspCampaignOrder(
        orderId: _int(json['order_id']) ?? 0,
        customer: json['customer']?.toString() ?? '',
        orderTo: json['order_to']?.toString() ?? '',
        date: json['date']?.toString() ?? '',
        amount: _double(json['amount']),
        status: json['status']?.toString() ?? '',
        processFlag: json['process_flag']?.toString() ?? '',
        invoiceCount: _int(json['invoice_count']) ?? 0,
      );
}

class AspCampaignProduct {
  const AspCampaignProduct({
    required this.id,
    required this.name,
    required this.category,
    required this.rate,
  });

  final int id;
  final String name;
  final String category;
  final double rate;

  factory AspCampaignProduct.fromJson(Map<String, dynamic> json) =>
      AspCampaignProduct(
        id: _int(json['id']) ?? 0,
        name: json['name']?.toString() ?? '',
        category: json['category']?.toString() ?? '',
        rate: _double(json['rate']),
      );
}

class AspCampaignOptions {
  const AspCampaignOptions({
    required this.customers,
    required this.orderTo,
    required this.products,
  });

  final List<Map<String, dynamic>> customers;
  final List<Map<String, dynamic>> orderTo;
  final List<AspCampaignProduct> products;

  factory AspCampaignOptions.fromJson(Map<String, dynamic> json) =>
      AspCampaignOptions(
        customers: _maps(json['customers']),
        orderTo: _maps(json['order_to']),
        products: _maps(json['products'])
            .map(AspCampaignProduct.fromJson)
            .toList(growable: false),
      );
}

int? _int(dynamic value) =>
    value is num ? value.toInt() : int.tryParse('$value');
double _double(dynamic value) =>
    value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
List<Map<String, dynamic>> _maps(dynamic value) => value is! List
    ? const []
    : value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
