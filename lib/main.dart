import 'package:flutter/material.dart';
import 'app.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/fcm_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    debugPrint('Firebase initialized successfully');

    // Initialize Firebase Cloud Messaging
    await FCMService.initialize();
  } catch (e, stackTrace) {
    debugPrint('Firebase/FCM initialization failed: $e');
    debugPrintStack(stackTrace: stackTrace);
  }

  // Start existing SDL PSR application
  runApp(const SdlPsrApp());
}
