import 'package:flutter_test/flutter_test.dart';

import 'package:sdl_psr_field_app/models/dashboard_data.dart';

void main() {
  test('builds the legacy dashboard sales summary from API summary fields', () {
    final dashboard = DashboardData.fromJson({
      'sales': {
        'cy_target': '125.50',
        'cy_sale': '92.25',
        'ly_sale': '88.75',
        'ytm_achievement': 73.51,
        'ytm_growth': 3.94,
      },
    });

    expect(dashboard.toSummary(), [
      {'title': 'CY TGT', 'value': '125.50'},
      {
        'title': 'CY Sale',
        'value': '92.25',
        'badge': '73.51% YTM Ach',
      },
      {
        'title': 'LY Sale',
        'value': '88.75',
        'badge': '3.94% Growth',
      },
    ]);
  });

  test('uses existing cumulative sales fields with the requested labels', () {
    final dashboard = DashboardData.fromJson({
      'sales': {
        'ytm_target': 100000,
        'ytm_sale': 80000,
        'last_year_ytm_sale': 75000,
        'ytm_achievement': 80,
        'ytm_growth': 6.67,
      },
    });

    expect(dashboard.toSummary(), [
      {'title': 'CY TGT', 'value': '100000'},
      {'title': 'CY Sale', 'value': '80000', 'badge': '80% YTM Ach'},
      {'title': 'LY Sale', 'value': '75000', 'badge': '6.67% Growth'},
    ]);
  });
}
