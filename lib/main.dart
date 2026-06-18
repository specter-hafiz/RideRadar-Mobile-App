import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shuttletrack/app.dart';
import 'package:shuttletrack/core/services/notification_service.dart';
import 'package:shuttletrack/di/injection_container.dart';
import 'package:shuttletrack/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase init can hang or fail (e.g. the web SDK failing to load from
  // gstatic, an offline/blocked network, or a bad config). Guard it with a
  // timeout and swallow errors so the UI always boots instead of getting
  // stuck on the splash screen forever.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 8));
  } catch (e, st) {
    debugPrint('Firebase initialization failed (continuing without it): $e\n$st');
  }

  await initDependencies();

  try {
    await sl<NotificationService>().initialize();
  } catch (e) {
    debugPrint('Notification initialization failed (continuing): $e');
  }

  runApp(const RideRadarApp());
}
