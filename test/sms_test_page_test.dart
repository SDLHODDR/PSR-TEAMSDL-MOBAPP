import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdl_psr_field_app/core/api/api_client.dart';
import 'package:sdl_psr_field_app/services/route_service.dart';
import 'package:sdl_psr_field_app/views/pages/sms_test_page.dart';

void main() {
  testWidgets('sends consent OTP only after customer consent is selected',
      (tester) async {
    final apiClient = _SmsTestApiClient();

    await tester.pumpWidget(
      MaterialApp(
        home: SmsTestPage(service: RouteService(apiClient: apiClient)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<int>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('7 - Test Town').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<int>).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Test Customer').last);
    await tester.pumpAndSettle();

    final sendButton =
        find.widgetWithText(FilledButton, 'Send consent OTP');
    expect(tester.widget<FilledButton>(sendButton).onPressed, isNull);
    expect(
      find.text('OTP will be sent to the registered phone ending 7890.'),
      findsOneWidget,
    );

    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(sendButton).onPressed, isNotNull);

    await tester.tap(sendButton);
    await tester.pumpAndSettle();

    expect(apiClient.requestedRouteId, 7);
    expect(apiClient.requestedCustomerId, 101);
    expect(find.text("Consent OTP sent. Check the customer's registered phone."),
        findsOneWidget);
  });
}

class _SmsTestApiClient extends ApiClient {
  int? requestedRouteId;
  int? requestedCustomerId;

  @override
  Future<Map<String, dynamic>> routes() async => {
        'routes': [
          {
            'route_id': 7,
            'town': 'Test Town',
            'customer_count': 1,
            'verified_count': 0,
            'unverified_count': 1,
          },
        ],
      };

  @override
  Future<Map<String, dynamic>> routeCustomers(int routeId) async => {
        'route': {
          'route_id': routeId,
          'town': 'Test Town',
        },
        'customers': [
          {
            'customer_id': 101,
            'name': 'Test Customer',
            'customer_type': 'Retailer',
            'customer_type_id': 2,
            'verified': false,
            'primary_phone': '1234567890',
            'otp_pending': false,
          },
        ],
      };

  @override
  Future<Map<String, dynamic>> requestRouteCustomerConsentOtp(
    int routeId,
    int customerId,
  ) async {
    requestedRouteId = routeId;
    requestedCustomerId = customerId;
    return {'retry_after_seconds': 120};
  }
}
