import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/auth_models.dart';
import '../../models/dashboard_data.dart';
import '../../models/employee_context.dart';
import 'api_config.dart';
import 'api_exception.dart';
import 'auth_events.dart';
import 'token_storage.dart';

class ApiClient {
  ApiClient({
    http.Client? client,
    TokenStorage? tokenStorage,
    String baseUrl = ApiConfig.baseUrl,
  })  : _client = client ?? http.Client(),
        _tokenStorage = tokenStorage ?? TokenStorage(),
        _baseUrl = baseUrl.replaceFirst(RegExp(r'/$'), '');

  final http.Client _client;
  final TokenStorage _tokenStorage;
  final String _baseUrl;

  Future<AuthSession> login(String username, String password) async {
    final data = await _requestData(
      'POST',
      '/api/v1/auth/login',
      body: {'username': username, 'password': password},
      authenticated: false,
    );
    final session = AuthSession.fromData(data);
    if (session.accessToken.isEmpty || session.accessExpiresAt == null) {
      throw const ApiException(message: 'The login response was incomplete.');
    }
    await _tokenStorage.saveAccessToken(
      accessToken: session.accessToken,
      expiresAt: session.accessExpiresAt!,
    );
    AuthEventBus.instance.authenticated();
    return session;
  }

  Future<EmployeeContext> me() async {
    final data = await _requestData('GET', '/api/v1/auth/me');
    return EmployeeContext.fromJson(data);
  }

  Future<DashboardData> dashboard() async {
    final data = await _requestData('GET', '/api/v1/dashboard');
    return DashboardData.fromJson(data);
  }

  Future<Map<String, dynamic>> priceList() =>
      _requestData('GET', '/api/v1/price-list');

  Future<Map<String, dynamic>> nonFieldActivityOptions() =>
      _requestData('GET', '/api/v1/non-field-activities/options');

  Future<Map<String, dynamic>> nonFieldActivities() =>
      _requestData('GET', '/api/v1/non-field-activities');

  Future<Map<String, dynamic>> saveNonFieldActivity(
    Map<String, dynamic> body,
  ) =>
      _requestData('POST', '/api/v1/non-field-activities', body: body);

  Future<Map<String, dynamic>> tourPlans(String month) => _requestData(
        'GET',
        '/api/v1/tour-plans?month=${Uri.encodeQueryComponent(month)}',
      );

  Future<Map<String, dynamic>> tourPlanActivities() =>
      _requestData('GET', '/api/v1/tour-plans/activities');

  Future<Map<String, dynamic>> tourPlanRoutes(String date) => _requestData(
        'GET',
        '/api/v1/tour-plans/routes?date=${Uri.encodeQueryComponent(date)}',
      );

  Future<Map<String, dynamic>> saveTourPlanDraft(
    Map<String, dynamic> body,
  ) =>
      _requestData('POST', '/api/v1/tour-plans/draft', body: body);

  Future<Map<String, dynamic>> submitTourPlan(
    Map<String, dynamic> body,
  ) =>
      _requestData('POST', '/api/v1/tour-plans/submit', body: body);

  Future<Map<String, dynamic>> routes() =>
      _requestData('GET', '/api/v1/routes');

  Future<Map<String, dynamic>> routeCustomers(int routeId) =>
      _requestData('GET', '/api/v1/routes/$routeId/customers');

  Future<Map<String, dynamic>> routeCustomer(int routeId, int customerId) =>
      _requestData('GET', '/api/v1/routes/$routeId/customers/$customerId');

  Future<Map<String, dynamic>> updateRouteCustomer(
    int routeId,
    int customerId,
    Map<String, dynamic> body,
  ) =>
      _requestData(
        'PUT',
        '/api/v1/routes/$routeId/customers/$customerId',
        body: body,
      );

  Future<Map<String, dynamic>> requestRouteCustomerConsentOtp(
    int routeId,
    int customerId,
  ) =>
      _requestData(
        'POST',
        '/api/v1/routes/$routeId/customers/$customerId/consent/otp',
        body: const {'consent': true},
      );

  Future<Map<String, dynamic>> verifyRouteCustomerConsentOtp(
    int routeId,
    int customerId,
    String otp,
  ) =>
      _requestData(
        'POST',
        '/api/v1/routes/$routeId/customers/$customerId/consent/verify',
        body: {'otp': otp},
      );

  Future<void> logout() async {
    await _tokenStorage.clear();
  }

  Future<Map<String, dynamic>> _requestData(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) async {
    final accessToken =
        authenticated ? await _tokenStorage.readAccessToken() : null;
    if (authenticated && (accessToken == null || accessToken.isEmpty)) {
      await _expireSession();
      throw const ApiException(
          message: 'Your session has expired. Please sign in again.');
    }
    if (authenticated && await _tokenIsExpired()) {
      await _expireSession();
      throw const ApiException(
          message: 'Your session has expired. Please sign in again.');
    }

    final response = await _send(
      method,
      path,
      body: body,
      accessToken: accessToken,
    );

    if (response.statusCode == 401 && authenticated) {
      await _expireSession();
      throw const ApiException(
          message: 'Your session has expired. Please log in again.',
          statusCode: 401);
    }

    return _decodeData(response);
  }

  Future<bool> _tokenIsExpired() async {
    final expiresAt = await _tokenStorage.readAccessTokenExpiry();
    return expiresAt == null || !DateTime.now().toUtc().isBefore(expiresAt);
  }

  Future<void> _expireSession() async {
    await _tokenStorage.clear();
    AuthEventBus.instance.sessionExpired();
  }

  Future<http.Response> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    String? accessToken,
  }) async {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (accessToken != null && accessToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $accessToken';
    }

    try {
      final uri = Uri.parse('$_baseUrl$path');
      final encodedBody = body == null ? null : jsonEncode(body);
      switch (method) {
        case 'GET':
          return await _client
              .get(uri, headers: headers)
              .timeout(const Duration(seconds: 20));
        case 'POST':
          return await _client
              .post(uri, headers: headers, body: encodedBody)
              .timeout(const Duration(seconds: 20));
        case 'PUT':
          return await _client
              .put(uri, headers: headers, body: encodedBody)
              .timeout(const Duration(seconds: 20));
        default:
          throw const ApiException(message: 'Unsupported API request.');
      }
    } on TimeoutException {
      throw const ApiException(message: 'The server took too long to respond.');
    } on http.ClientException {
      throw const ApiException(message: 'Unable to connect to the API server.');
    } on FormatException {
      throw const ApiException(
          message: 'The API URL is not configured correctly.');
    }
  }

  Map<String, dynamic> _decodeData(http.Response response) {
    Map<String, dynamic> payload;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) throw const FormatException();
      payload = Map<String, dynamic>.from(decoded);
    } on FormatException {
      throw const ApiException(
          message: 'The API returned an invalid response.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final error = payload['error'];
      final code = error is Map ? error['code'] as String? : null;
      throw ApiException(
        message: payload['message'] as String? ?? 'The API request failed.',
        statusCode: response.statusCode,
        code: code,
      );
    }

    final data = payload['data'];
    if (data is! Map) {
      throw const ApiException(message: 'The API response is missing data.');
    }
    return Map<String, dynamic>.from(data);
  }
}
