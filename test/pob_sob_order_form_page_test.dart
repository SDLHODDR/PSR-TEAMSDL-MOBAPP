import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdl_psr_field_app/models/pob_sob_data.dart';
import 'package:sdl_psr_field_app/services/pob_sob_service.dart';
import 'package:sdl_psr_field_app/views/pages/pob_sob_order_form_page.dart';

void main() {
  testWidgets('Order To options are available before selecting a customer',
      (tester) async {
    final service = _OptionsService(
      PobSobOptions(
        date: DateTime(2026, 11, 17),
        customers: const [
          PobSobCustomer(id: 1, name: 'Test Customer', code: 'C1'),
        ],
        orderToOptions: const [
          PobSobOrderTo(id: 2, name: 'Test Distributor (D1)'),
        ],
        products: const [],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(home: PobSobOrderFormPage(service: service)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Order To'));
    await tester.pumpAndSettle();

    expect(find.text('Test Distributor (D1)'), findsOneWidget);
  });
}

class _OptionsService extends PobSobService {
  _OptionsService(this.options) : super();

  final PobSobOptions options;

  @override
  Future<PobSobOptions> loadOptions({int? customerId}) async => options;
}
