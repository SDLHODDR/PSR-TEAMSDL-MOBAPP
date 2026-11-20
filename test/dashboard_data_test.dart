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

  test('parses reporting gaps and open requests for the activity gate', () {
    final dashboard = DashboardData.fromJson({
      'non_reporting_days': ['12-Jun-2025'],
      'open_requests': [
        {'DATE_LABEL': '13-Jun', 'DAY_DATE': '13-Jun-2025'},
      ],
    });

    expect(dashboard.nonReportingDays, ['12-Jun-2025']);
    expect(dashboard.openRequests, ['13-Jun-2025']);
    expect(dashboard.hasReportingBlock, isTrue);
  });

  test('preserves reporting status for rejected and delayed dates', () {
    final dashboard = DashboardData.fromJson({
      'reporting_status': [
        {'date': '13-Nov-2026', 'status': 'Rejected'},
        {'date': '14-Nov-2026', 'status': 'Delayed'},
      ],
    });

    expect(dashboard.reportingAlerts.map((item) => item.label), [
      'Rejected',
      'Delayed Reporting',
    ]);
  });

  test('normalizes short reporting status codes', () {
    final dashboard = DashboardData.fromJson({
      'reporting_status': [
        {'date': '14-Nov-2026', 'status': 'R'},
        {'date': '16-Nov-2026', 'status': 'D'},
      ],
    });

    expect(dashboard.reportingAlerts[0].label, 'Rejected');
    expect(dashboard.reportingAlerts[1].label, 'Delayed Reporting');
  });

  test('keeps delayed open requests when another reporting status exists', () {
    final dashboard = DashboardData.fromJson({
      'reporting_status': [
        {'date': '14-Nov-2026', 'status': 'rejected'},
      ],
      'open_requests': [
        {'DAY_DATE': '16-Nov-2026'},
      ],
    });

    expect(dashboard.reportingAlerts.map((item) => item.label), [
      'Rejected',
      'Delayed Reporting',
    ]);
  });
}
