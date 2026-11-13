import 'package:flutter_test/flutter_test.dart';
import 'package:sdl_psr_field_app/core/api/api_client.dart';
import 'package:sdl_psr_field_app/services/reports_service.dart';

void main() {
  test('requests the selected month and parses legacy day summaries', () async {
    final apiClient = _ReportsApiClient(
      monthlyResponse: {
        'month': '2026-11',
        'label': 'Nov-2026',
        'days': [
          {
            'date': '2026-11-02',
            'day': '02',
            'kind': 'route',
            'summary': 'Ashoka Marg',
            'route_id': '2',
            'pob': 840,
            'sob': 0,
            'has_details': true,
          },
        ],
      },
    );
    final service = ReportsService(apiClient: apiClient);

    final report = await service.loadMonth(DateTime(2026, 11));

    expect(apiClient.requestedMonth, '2026-11');
    expect(report.label, 'Nov-2026');
    expect(report.days.single.summary, 'Ashoka Marg');
    expect(report.days.single.hasDetails, isTrue);
  });

  test('loads customer POB details for a selected report day', () async {
    final apiClient = _ReportsApiClient(
      monthlyResponse: const {'month': '2026-11', 'label': 'Nov-2026', 'days': []},
      dailyResponse: {
        'date': '2026-11-02',
        'details': [
          {
            'customer': 'Pushpaswaroop Medical',
            'pob': 840,
            'route_id': '2',
            'unlisted': false,
          },
        ],
      },
    );
    final service = ReportsService(apiClient: apiClient);

    final report = await service.loadDay(DateTime(2026, 11, 2));

    expect(apiClient.requestedDate, '2026-11-02');
    expect(report.details.single.customer, 'Pushpaswaroop Medical');
    expect(report.details.single.pob, 840);
  });
}

class _ReportsApiClient extends ApiClient {
  _ReportsApiClient({
    required this.monthlyResponse,
    this.dailyResponse = const {'date': '2026-11-02', 'details': []},
  });

  final Map<String, dynamic> monthlyResponse;
  final Map<String, dynamic> dailyResponse;
  String? requestedMonth;
  String? requestedDate;

  @override
  Future<Map<String, dynamic>> monthlyReport(String month) async {
    requestedMonth = month;
    return monthlyResponse;
  }

  @override
  Future<Map<String, dynamic>> dailyReport(String date) async {
    requestedDate = date;
    return dailyResponse;
  }
}
