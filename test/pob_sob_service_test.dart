import 'package:flutter_test/flutter_test.dart';
import 'package:sdl_psr_field_app/core/api/api_client.dart';
import 'package:sdl_psr_field_app/services/pob_sob_service.dart';

void main() {
  test('requests the selected month and parses POB/SOB totals and orders',
      () async {
    final apiClient = _PobSobApiClient({
      'month': '2026-10',
      'label': 'October 2026',
      'days': [
        {
          'date': '2026-10-01',
          'day': '01',
          'is_future': false,
          'customer_count': 1,
          'total': 1250,
          'pob_total': 1250,
          'sob_total': 0,
          'orders': [
            {
              'customer_id': 120,
              'customer': 'Aadhar Medical Store',
              'order_to': 'Aadhar Medical Store',
              'type': 'POB',
              'amount': 1250,
              'status': 'A',
              'process_flag': 'Y',
              'otp_available': true,
              'verified_at': '2026-10-01 10:30 AM',
              'source': 'CP',
              'plan_id': 4501,
            },
          ],
        },
      ],
    });
    final service = PobSobService(apiClient: apiClient);

    final result = await service.loadMonth(DateTime(2026, 10));

    expect(apiClient.requestedMonth, '2026-10');
    expect(result.label, 'October 2026');
    expect(result.days.single.pobTotal, 1250);
    expect(result.days.single.orders.single.customer, 'Aadhar Medical Store');
    expect(result.days.single.orders.single.type, 'POB');
    expect(result.days.single.orders.single.verifiedAt, '2026-10-01 10:30 AM');
  });

  test('rejects malformed monthly payloads', () async {
    final service = PobSobService(
      apiClient: _PobSobApiClient(
        const {
          'month': '2026-10',
          'label': 'October 2026',
          'days': ['bad']
        },
      ),
    );

    await expectLater(
      service.loadMonth(DateTime(2026, 10)),
      throwsA(isA<Exception>()),
    );
  });
}

class _PobSobApiClient extends ApiClient {
  _PobSobApiClient(this.response);

  final Map<String, dynamic> response;
  String? requestedMonth;

  @override
  Future<Map<String, dynamic>> pobSobOrders(String month) async {
    requestedMonth = month;
    return response;
  }
}
