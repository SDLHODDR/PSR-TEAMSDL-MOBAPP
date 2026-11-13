class MonthlyReportDay {
  const MonthlyReportDay({
    required this.date,
    required this.day,
    required this.kind,
    required this.summary,
    required this.routeId,
    required this.pob,
    required this.sob,
    required this.hasDetails,
  });

  final DateTime date;
  final int day;
  final String kind;
  final String summary;
  final String? routeId;
  final double pob;
  final double sob;
  final bool hasDetails;

  factory MonthlyReportDay.fromJson(Map<String, dynamic> json) {
    final date = DateTime.tryParse(json['date']?.toString() ?? '');
    final day = _int(json['day']);
    final kind = json['kind']?.toString().trim() ?? '';
    final summary = json['summary']?.toString() ?? '';
    final pob = _number(json['pob']);
    final sob = _number(json['sob']);
    if (date == null ||
        day == null ||
        day < 1 ||
        day > 31 ||
        kind.isEmpty ||
        pob == null ||
        sob == null) {
      throw const FormatException('Invalid monthly report day.');
    }
    return MonthlyReportDay(
      date: date,
      day: day,
      kind: kind,
      summary: summary,
      routeId: json['route_id']?.toString(),
      pob: pob,
      sob: sob,
      hasDetails: json['has_details'] == true,
    );
  }
}

class MonthlyReport {
  const MonthlyReport({
    required this.month,
    required this.label,
    required this.days,
  });

  final String month;
  final String label;
  final List<MonthlyReportDay> days;

  factory MonthlyReport.fromJson(Map<String, dynamic> json) {
    final month = json['month']?.toString().trim() ?? '';
    final label = json['label']?.toString().trim() ?? '';
    final daysValue = json['days'];
    if (month.isEmpty || label.isEmpty || daysValue is! List) {
      throw const FormatException('Invalid monthly report.');
    }
    return MonthlyReport(
      month: month,
      label: label,
      days: daysValue.map((value) {
        if (value is! Map) {
          throw const FormatException('Invalid monthly report day.');
        }
        return MonthlyReportDay.fromJson(Map<String, dynamic>.from(value));
      }).toList(growable: false),
    );
  }
}

class DailyReportDetail {
  const DailyReportDetail({
    required this.customer,
    required this.pob,
    required this.routeId,
    required this.unlisted,
  });

  final String customer;
  final double pob;
  final String? routeId;
  final bool unlisted;

  factory DailyReportDetail.fromJson(Map<String, dynamic> json) {
    final customer = json['customer']?.toString().trim() ?? '';
    final pob = _number(json['pob']);
    if (customer.isEmpty || pob == null) {
      throw const FormatException('Invalid daily report detail.');
    }
    return DailyReportDetail(
      customer: customer,
      pob: pob,
      routeId: json['route_id']?.toString(),
      unlisted: json['unlisted'] == true,
    );
  }
}

class DailyReport {
  const DailyReport({required this.date, required this.details});

  final DateTime date;
  final List<DailyReportDetail> details;

  factory DailyReport.fromJson(Map<String, dynamic> json) {
    final date = DateTime.tryParse(json['date']?.toString() ?? '');
    final detailsValue = json['details'];
    if (date == null || detailsValue is! List) {
      throw const FormatException('Invalid daily report.');
    }
    return DailyReport(
      date: date,
      details: detailsValue.map((value) {
        if (value is! Map) {
          throw const FormatException('Invalid daily report detail.');
        }
        return DailyReportDetail.fromJson(Map<String, dynamic>.from(value));
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
