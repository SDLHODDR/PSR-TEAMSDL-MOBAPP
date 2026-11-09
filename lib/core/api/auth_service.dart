import '../../models/employee_context.dart';
import '../../models/dashboard_data.dart';
import 'api_client.dart';
import 'api_exception.dart';
import 'auth_events.dart';
import 'token_storage.dart';

class AuthService {
  AuthService._() {
    AuthEventBus.instance.stream.listen((event) {
      if (event == AuthEventType.sessionExpired) currentEmployee = null;
    });
  }

  static final AuthService instance = AuthService._();

  final ApiClient _client = ApiClient();
  final TokenStorage _storage = TokenStorage();

  EmployeeContext? currentEmployee;
  bool _restoringSession = false;

  bool get isRestoringSession => _restoringSession;

  Future<EmployeeContext> login(String username, String password) async {
    await _client.login(username, password);
    try {
      currentEmployee = await _client.me();
      return currentEmployee!;
    } on ApiException {
      await _storage.clear();
      currentEmployee = null;
      rethrow;
    }
  }

  Future<EmployeeContext?> restoreSession() async {
    _restoringSession = true;
    try {
      return await _restoreSession();
    } finally {
      _restoringSession = false;
    }
  }

  Future<EmployeeContext?> _restoreSession() async {
    final token = await _storage.readAccessToken();
    if (token == null || token.isEmpty) return null;
    final expiresAt = await _storage.readAccessTokenExpiry();
    if (expiresAt == null || !DateTime.now().toUtc().isBefore(expiresAt)) {
      await clearSession();
      return null;
    }

    try {
      currentEmployee = await _client.me();
      return currentEmployee;
    } on ApiException {
      await _storage.clear();
      currentEmployee = null;
      return null;
    }
  }

  Future<bool> checkSession() async {
    final token = await _storage.readAccessToken();
    final expiresAt = await _storage.readAccessTokenExpiry();
    if (token == null ||
        token.isEmpty ||
        expiresAt == null ||
        !DateTime.now().toUtc().isBefore(expiresAt)) {
      await clearSession(notify: true);
      return false;
    }
    return true;
  }

  Future<DashboardData> loadDashboard() => _client.dashboard();

  Future<void> logout() async {
    await clearSession();
  }

  Future<void> clearSession({bool notify = false}) async {
    await _storage.clear();
    currentEmployee = null;
    if (notify) AuthEventBus.instance.sessionExpired();
  }
}
