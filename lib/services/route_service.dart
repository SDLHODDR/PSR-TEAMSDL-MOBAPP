import '../core/api/api_client.dart';
import '../core/api/api_exception.dart';
import '../models/route_data.dart';

class RouteService {
  RouteService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<RouteSummary>> loadRoutes() async {
    final data = await _apiClient.routes();
    final values = data['routes'];
    if (values is! List) {
      throw const ApiException(message: 'The routes response is invalid.');
    }
    return values.map((value) {
      if (value is! Map) {
        throw const ApiException(message: 'The routes response is invalid.');
      }
      return RouteSummary.fromJson(Map<String, dynamic>.from(value));
    }).toList(growable: false);
  }

  Future<(RouteSummary, List<RouteCustomer>)> loadCustomers(
    int routeId,
    RouteSummary summary,
  ) async {
    final data = await _apiClient.routeCustomers(routeId);
    final route = data['route'];
    final values = data['customers'];
    if (route is! Map || values is! List) {
      throw const ApiException(
          message: 'The route customers response is invalid.');
    }
    final routeData = Map<String, dynamic>.from(route);
    final routeSummary = RouteSummary(
      routeId: _int(routeData['route_id']) ?? summary.routeId,
      town: routeData['town']?.toString() ?? summary.town,
      customerCount: values.length,
      verifiedCount: values.where((value) {
        return value is Map && value['verified'] == true;
      }).length,
      unverifiedCount: values.where((value) {
        return value is Map && value['verified'] != true;
      }).length,
    );
    final customers = values.map((value) {
      if (value is! Map) {
        throw const ApiException(
            message: 'The route customers response is invalid.');
      }
      return RouteCustomer.fromJson(Map<String, dynamic>.from(value));
    }).toList(growable: false);
    return (routeSummary, customers);
  }

  Future<RouteCustomerProfile> loadCustomer(int routeId, int customerId) async {
    final data = await _apiClient.routeCustomer(routeId, customerId);
    final value = data['customer'];
    if (value is! Map) {
      throw const ApiException(
          message: 'The customer details response is invalid.');
    }
    return RouteCustomerProfile.fromJson(Map<String, dynamic>.from(value));
  }

  Future<RouteCustomerProfile> saveCustomer(
    int routeId,
    RouteCustomerProfile profile,
  ) async {
    final data = await _apiClient.updateRouteCustomer(
      routeId,
      profile.customerId,
      profile.toProfileJson(),
    );
    final value = data['customer'];
    if (value is! Map) {
      throw const ApiException(
          message: 'The saved customer response is invalid.');
    }
    return RouteCustomerProfile.fromJson(Map<String, dynamic>.from(value));
  }

  Future<int> requestConsentOtp(int routeId, int customerId) async {
    final data =
        await _apiClient.requestRouteCustomerConsentOtp(routeId, customerId);
    return _int(data['retry_after_seconds']) ?? 120;
  }

  Future<void> verifyConsentOtp(
    int routeId,
    int customerId,
    String otp,
  ) async {
    await _apiClient.verifyRouteCustomerConsentOtp(routeId, customerId, otp);
  }

  int? _int(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}
