class ReportingAlert {
  const ReportingAlert({required this.date, required this.status});

  final String date;
  final String status;

  String get normalizedStatus =>
      status.toLowerCase().trim().replaceAll(RegExp(r'[ -]+'), '_');

  String get statusKey {
    switch (normalizedStatus) {
      case 'r':
      case 'reject':
      case 'rejected':
        return 'rejected';
      case 'd':
      case 'delay':
      case 'delayed':
        return 'delayed';
      case 'n':
      case 'nr':
      case 'nonreported':
      case 'non_reported':
      case 'not_reported':
      case 'non_reporting':
        return 'non_reported';
      default:
        return normalizedStatus;
    }
  }

  String get label {
    switch (statusKey) {
      case 'rejected':
        return 'Rejected';
      case 'delayed':
        return 'Delayed Reporting';
      case 'pending':
      case 'pending_report':
      case 'pending_reports':
        return 'Pending reports';
      case 'non_reported':
      default:
        return 'Not reported';
    }
  }
}

class DashboardData {
  const DashboardData({
    this.cyTarget,
    this.cySale,
    this.lySale,
    this.ytmTarget,
    this.ytmSale,
    this.lastYearYtmSale,
    this.ytmAchievement,
    this.growth,
    this.nonReportingDays = const [],
    this.openRequests = const [],
    this.reportingAlerts = const [],
  });

  final String? cyTarget;
  final String? cySale;
  final String? lySale;
  final String? ytmTarget;
  final String? ytmSale;
  final String? lastYearYtmSale;
  final String? ytmAchievement;
  final String? growth;
  final List<String> nonReportingDays;
  final List<String> openRequests;
  final List<ReportingAlert> reportingAlerts;

  bool get hasReportingBlock =>
      reportingAlerts.isNotEmpty ||
      nonReportingDays.isNotEmpty ||
      openRequests.isNotEmpty;

  bool get hasSalesMetrics =>
      cyTarget != null ||
      cySale != null ||
      lySale != null ||
      ytmTarget != null ||
      ytmSale != null ||
      lastYearYtmSale != null;

  factory DashboardData.fromJson(Map<String, dynamic> source) {
    final json = _unwrap(source);
    final sales = _map(json['sales']);
    final nonReportingDays = _stringList(json['non_reporting_days']);
    final openRequests = _dateList(json['open_requests']);
    final reportingAlerts = _mergeReportingAlerts(
      explicit: _reportingAlerts(json),
      nonReportingDays: nonReportingDays,
      openRequests: json['open_requests'],
    );
    return DashboardData(
      cyTarget: _value(sales, const ['cy_target', 'cyTgt', 'cyTarget']) ??
          _value(json, const ['cyTgt', 'cy_target', 'cyTarget']) ??
          _value(sales, const ['ytm_target', 'ytmTgt', 'ytmTarget']),
      cySale: _value(sales, const ['cy_sale', 'cySale', 'cySales']) ??
          _value(json, const ['cySale', 'cy_sale', 'cySales']) ??
          _value(sales, const ['ytm_sale', 'ytmSale']),
      lySale: _value(sales, const ['ly_sale', 'lySale', 'lySales']) ??
          _value(json, const ['lySale', 'ly_sale', 'lySales']) ??
          _value(sales, const ['last_year_ytm_sale', 'lyYtmSale']),
      ytmTarget: _value(sales, const ['ytm_target', 'ytmTgt', 'ytmTarget']),
      ytmSale: _value(sales, const ['ytm_sale', 'ytmSale']),
      lastYearYtmSale: _value(
        sales,
        const ['last_year_ytm_sale', 'lyYtmSale', 'lastYearYtmSale'],
      ),
      ytmAchievement: _value(
        sales.isNotEmpty ? sales : json,
        const ['ytm_achievement', 'ytmAch', 'ytm_ach', 'ytmAchievement'],
      ),
      growth: _value(
        sales.isNotEmpty ? sales : json,
        const ['ytm_growth', 'ytmGrth', 'ytm_grth', 'growth'],
      ),
      nonReportingDays: nonReportingDays,
      openRequests: openRequests,
      reportingAlerts: reportingAlerts,
    );
  }

  List<Map<String, dynamic>> toSummary() {
    return [
      {
        'title': 'CY TGT',
        'value': (cyTarget ?? ytmTarget) ?? '0',
      },
      {
        'title': 'CY Sale',
        'value': (cySale ?? ytmSale) ?? '0',
        'badge': ytmAchievement == null ? null : '$ytmAchievement% YTM Ach',
      },
      {
        'title': 'LY Sale',
        'value': (lySale ?? lastYearYtmSale) ?? '0',
        'badge': growth == null ? null : '$growth% Growth',
      },
    ];
  }
}

Map<String, dynamic> _unwrap(Map<String, dynamic> source) {
  final dashboard = source['dashboard'];
  return dashboard is Map
      ? Map<String, dynamic>.from(dashboard)
      : Map<String, dynamic>.from(source);
}

Map<String, dynamic> _map(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

String? _value(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value == null) continue;
    final text = value.toString().trim();
    if (text.isNotEmpty) return text;
  }
  return null;
}

List<String> _stringList(dynamic value) {
  if (value is! List) return const [];
  return value
      .map((item) => item?.toString().trim() ?? '')
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}

List<String> _dateList(dynamic value) {
  if (value is! List) return const [];
  return value
      .map((item) {
        if (item is Map) {
          final row = Map<String, dynamic>.from(item);
          return _value(row,
                  const ['day_date', 'DAY_DATE', 'date_label', 'DATE_LABEL']) ??
              '';
        }
        return item?.toString().trim() ?? '';
      })
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}

List<ReportingAlert> _reportingAlerts(Map<String, dynamic> json) {
  for (final key in const [
    'reporting_status',
    'reporting_statuses',
    'reporting_days',
    'reporting_alerts',
  ]) {
    final value = json[key];
    if (value is List) {
      final alerts = _alertList(value, defaultStatus: 'non_reported');
      if (alerts.isNotEmpty) return alerts;
    }
  }
  return const [];
}

List<ReportingAlert> _requestAlerts(dynamic value) {
  if (value is! List) return const [];
  return _alertList(value, defaultStatus: 'delayed');
}

List<ReportingAlert> _mergeReportingAlerts({
  required List<ReportingAlert> explicit,
  required List<String> nonReportingDays,
  required dynamic openRequests,
}) {
  final alerts = <ReportingAlert>[
    ...explicit,
    ...nonReportingDays.map(
      (date) => ReportingAlert(date: date, status: 'non_reported'),
    ),
    ..._requestAlerts(openRequests),
  ];
  final seen = <String>{};
  return alerts.where((alert) {
    final key = '${alert.date}|${alert.statusKey}';
    return seen.add(key);
  }).toList(growable: false);
}

List<ReportingAlert> _alertList(
  List<dynamic> value, {
  required String defaultStatus,
}) {
  return value
      .map((item) {
        if (item is Map) {
          final row = Map<String, dynamic>.from(item);
          final date = _value(row, const [
            'day_date',
            'DAY_DATE',
            'date_label',
            'DATE_LABEL',
            'date',
            'report_date',
          ]);
          final status = _value(row, const [
            'status',
            'report_status',
            'request_status',
            'request_type',
            'reporting_type',
            'activity_status',
            'state',
            'type',
            'category',
          ]);
          if (date != null) {
            return ReportingAlert(
              date: date,
              status: status ?? defaultStatus,
            );
          }
        } else {
          final date = item?.toString().trim() ?? '';
          if (date.isNotEmpty) {
            return ReportingAlert(date: date, status: defaultStatus);
          }
        }
        return null;
      })
      .whereType<ReportingAlert>()
      .toList(growable: false);
}
