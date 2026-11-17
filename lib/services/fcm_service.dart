import 'package:firebase_messaging/firebase_messaging.dart';

class FCMService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<String?> initialize() async {
    // Request notification permission
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    print('Notification permission: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      print('Notification permission denied');
      return null;
    }

    // Get FCM device token
    final token = await _messaging.getToken();

    print('========================================');
    print('SDL PSR FCM DEVICE TOKEN');
    print(token);
    print('========================================');

    // Listen for token refresh
    _messaging.onTokenRefresh.listen((newToken) {
      print('FCM Token Refreshed: $newToken');
    });

    return token;
  }
}
