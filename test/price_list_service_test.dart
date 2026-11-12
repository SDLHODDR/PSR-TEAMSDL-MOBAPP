import 'package:flutter_test/flutter_test.dart';
import 'package:sdl_psr_field_app/core/api/api_client.dart';
import 'package:sdl_psr_field_app/services/price_list_service.dart';

void main() {
  test('loads products grouped by ordered primary categories from the API',
      () async {
    final service = PriceListService(
      apiClient: _PriceListApiClient({
        'effective_date': '2026-11-09',
        'categories': [
          {
            'category_id': 20,
            'name': 'Herbal Products',
            'sequence': 2,
            'products': [
              {'product_id': 102, 'name': 'Guduchi Capsules', 'rate': 150},
            ],
          },
          {
            'category_id': 10,
            'name': 'Classical',
            'sequence': 1,
            'products': [
              {'product_id': 101, 'name': 'Triphala Tablets', 'rate': '95.5'},
            ],
          },
        ],
      }),
    );

    final result = await service.load();

    expect(result.effectiveDate, '2026-11-09');
    expect(result.productCount, 2);
    expect(result.categories.map((category) => category.name),
        ['Classical', 'Herbal Products']);
    expect(result.categories.first.products.single.rate, 95.5);
  });
}

class _PriceListApiClient extends ApiClient {
  _PriceListApiClient(this.response);

  final Map<String, dynamic> response;

  @override
  Future<Map<String, dynamic>> priceList() async => response;
}
