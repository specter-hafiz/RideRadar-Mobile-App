import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shuttletrack/app.dart';
import 'package:shuttletrack/core/services/notification_service.dart';
import 'package:shuttletrack/di/injection_container.dart';
import 'package:shuttletrack/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initDependencies();
  await sl<NotificationService>().initialize();
  runApp(const RideRadarApp());
}
