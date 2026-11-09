import 'dart:async';

enum AuthEventType { authenticated, sessionExpired }

class AuthEventBus {
  AuthEventBus._();

  static final instance = AuthEventBus._();
  final _events = StreamController<AuthEventType>.broadcast();

  Stream<AuthEventType> get stream => _events.stream;

  void authenticated() => _events.add(AuthEventType.authenticated);

  void sessionExpired() => _events.add(AuthEventType.sessionExpired);
}
