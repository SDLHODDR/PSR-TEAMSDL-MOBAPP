import 'package:flutter_test/flutter_test.dart';
import 'package:sdl_psr_field_app/core/api/api_client.dart';
import 'package:sdl_psr_field_app/services/expenses_service.dart';

void main() {
  test('loads current and recent monthly expense summaries from the API',
      () async {
    final service = ExpensesService(
      apiClient: _ExpensesApiClient({
        'months': [
          {
            'month': '2026-11',
            'label': 'Nov-2026',
            'is_current': true,
            'status': 'notSubmitted',
            'status_code': null,
            'total': 250,
            'items': [
              {
                'type': 'Telephone Expense',
                'amount': 250,
                'remark': 'Recharge'
              },
            ],
          },
          {
            'month': '2026-10',
            'label': 'Oct-2026',
            'is_current': false,
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
            'is_current': false,
            'status': 'draft',
            'status_code': 'X',
            'total': 0,
            'items': [],
          },
          {
            'month': '2026-08',
            'label': 'Aug-2026',
            'is_current': false,
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
        ['Nov-2026', 'Oct-2026', 'Sep-2026', 'Aug-2026']);
    expect(result.months.first.isCurrent, isTrue);
    expect(result.months.first.items.single.type, 'Telephone Expense');
    expect(result.months[1].items.single.type, 'HQ Allowance');
    expect(result.months[1].total, 4500);
    expect(result.months.last.status, 'notSubmitted');
  });
}

class _ExpensesApiClient extends ApiClient {
  _ExpensesApiClient(this.response);

  final Map<String, dynamic> response;

  @override
  Future<Map<String, dynamic>> expenses() async => response;
}
