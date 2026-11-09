import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/api/auth_events.dart';
import 'core/api/auth_service.dart';
import 'core/theme/app_theme.dart';
import 'providers/employee_provider.dart';
import 'views/pages/login_page.dart';
import 'views/pages/splash_page.dart';

class SdlPsrApp extends StatefulWidget {
  const SdlPsrApp({super.key});

  @override
  State<SdlPsrApp> createState() => _SdlPsrAppState();
}

class _SdlPsrAppState extends State<SdlPsrApp> with WidgetsBindingObserver {
  final _navigatorKey = GlobalKey<NavigatorState>();
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  final _employeeProvider = EmployeeProvider();
  StreamSubscription<AuthEventType>? _authEvents;
  bool _redirectingToLogin = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _authEvents = AuthEventBus.instance.stream.listen(_handleAuthEvent);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authEvents?.cancel();
    _employeeProvider.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkSessionOnResume();
  }

  Future<void> _checkSessionOnResume() async {
    await AuthService.instance.checkSession();
  }

  void _handleAuthEvent(AuthEventType event) {
    if (event == AuthEventType.authenticated) {
      _redirectingToLogin = false;
      return;
    }
    // SplashPage owns the initial restore navigation. Avoid stacking a second
    // LoginPage if auth/me returns 401 during that startup check.
    if (AuthService.instance.isRestoringSession) {
      _employeeProvider.clearEmployee();
      return;
    }
    // An unauthenticated LoginPage does not need another LoginPage pushed on
    // top of it when the app resumes without stored credentials.
    if (!_employeeProvider.hasEmployee) return;
    if (_redirectingToLogin) return;
    _redirectingToLogin = true;
    _employeeProvider.clearEmployee();
    AuthService.instance.clearSession();
    _navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scaffoldMessengerKey.currentState
        ?..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
            content: Text('Your session has expired. Please log in again.')));
    });
  }

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider.value(
        value: _employeeProvider,
        child: MaterialApp(
          title: 'SDL PSR Field App',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          navigatorKey: _navigatorKey,
          scaffoldMessengerKey: _scaffoldMessengerKey,
          home: const SplashPage(),
        ),
      );
}
