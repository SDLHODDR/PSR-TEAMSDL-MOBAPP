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
              'order_id': 710,
              'source': 'CP',
              'customer_id': 120,
              'customer': 'Aadhar Medical Store',
              'order_to': 'Aadhar Medical Store',
              'type': 'POB',
              'amount': 1250,
              'status': 'A',
              'process_flag': 'Y',
              'otp_available': true,
              'verified_at': '2026-10-01 10:30 AM',
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
    expect(result.days.single.orders.single.orderId, 710);
    expect(result.days.single.orders.single.source, 'CP');
    expect(result.days.single.orders.single.type, 'POB');
    expect(result.days.single.orders.single.verifiedAt, '2026-10-01 10:30 AM');
  });

  test('loads invoice-ready order details', () async {
    final service = PobSobService(
      apiClient: _PobSobApiClient({
        'order_id': 710,
        'source': 'PO',
        'date': '2026-10-01',
        'date_label': '01-Oct-2026 10:30 AM',
        'customer_id': 120,
        'customer': 'Aadhar Medical Store',
        'customer_code': 'A120',
        'order_to_id': 456,
        'order_to': 'SDL Distributor',
        'type': 'POB',
        'amount': 250,
        'status': 'N',
        'process_flag': '',
        'verified_at': '',
        'employee': 'Test Employee',
        'can_edit': true,
        'items': [
          {
            'product_id': 789,
            'product': 'Test Product',
            'rate': 125,
            'quantity': 2,
            'free_quantity': 1,
            'amount': 250,
          },
        ],
      }),
    );

    final order = await service.loadOrderById(710, 'PO');

    expect(order.orderId, 710);
    expect(order.canEdit, isTrue);
    expect(order.items.single.product, 'Test Product');
    expect(order.items.single.amount, 250);
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

  @override
  Future<Map<String, dynamic>> pobSobOrder(int orderId, String source) async =>
      response;
}
