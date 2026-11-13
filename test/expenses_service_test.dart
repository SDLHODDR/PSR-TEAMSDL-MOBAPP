import 'package:flutter_test/flutter_test.dart';
import 'package:sdl_psr_field_app/core/api/api_client.dart';
import 'package:sdl_psr_field_app/services/expenses_service.dart';

void main() {
  test('loads monthly expense summaries from the API', () async {
    final service = ExpensesService(
      apiClient: _ExpensesApiClient({
        'months': [
          {
            'month': '2026-10',
            'label': 'Oct-2026',
            'status': 'submitted',
            'status_code': 'A',
            'total': 4500,
            'items': [
              {'type': 'HQ Allowance', 'amount': 4500, 'remark': ''},
            ],
          },
          {
            'month': '2026-09',
            'label': 'Sep-2026',
            'status': 'draft',
            'status_code': 'X',
            'total': 0,
            'items': [],
          },
          {
            'month': '2026-08',
            'label': 'Aug-2026',
            'status': 'notSubmitted',
            'status_code': null,
            'total': 0,
            'items': [],
          },
        ],
      }),
    );

    final result = await service.load();

    expect(result.months.map((month) => month.label),
        ['Oct-2026', 'Sep-2026', 'Aug-2026']);
    expect(result.months.first.items.single.type, 'HQ Allowance');
    expect(result.months.first.total, 4500);
    expect(result.months.last.status, 'notSubmitted');
  });
}

class _ExpensesApiClient extends ApiClient {
  _ExpensesApiClient(this.response);

  final Map<String, dynamic> response;

  @override
  Future<Map<String, dynamic>> expenses() async => response;
}
