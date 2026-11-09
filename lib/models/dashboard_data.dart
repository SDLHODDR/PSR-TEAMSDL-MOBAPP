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
  });

  final String? cyTarget;
  final String? cySale;
  final String? lySale;
  final String? ytmTarget;
  final String? ytmSale;
  final String? lastYearYtmSale;
  final String? ytmAchievement;
  final String? growth;

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
    return DashboardData(
      cyTarget: _value(json, const ['cyTgt', 'cy_target', 'cyTarget']),
      cySale: _value(json, const ['cySale', 'cy_sale', 'cySales']),
      lySale: _value(json, const ['lySale', 'ly_sale', 'lySales']),
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
    );
  }

  List<Map<String, dynamic>> toSummary() {
    final hasCurrentYearMetrics =
        cyTarget != null || cySale != null || lySale != null;
    return [
      {
        'title': hasCurrentYearMetrics ? 'CY TGT' : 'YTM TGT',
        'value': (hasCurrentYearMetrics ? cyTarget : ytmTarget) ?? '0',
      },
      {
        'title': hasCurrentYearMetrics ? 'CY Sale' : 'YTM Sale',
        'value': (hasCurrentYearMetrics ? cySale : ytmSale) ?? '0',
        'badge': ytmAchievement == null ? null : '$ytmAchievement% YTM Ach',
      },
      {
        'title': hasCurrentYearMetrics ? 'LY Sale' : 'LY YTM Sale',
        'value': (hasCurrentYearMetrics ? lySale : lastYearYtmSale) ?? '0',
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
