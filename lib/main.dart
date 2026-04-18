import 'package:flutter/material.dart';
import 'package:shuttletrack/app.dart';
import 'package:shuttletrack/core/services/notification_service.dart';
import 'package:shuttletrack/di/injection_container.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDependencies();
  await sl<NotificationService>().initialize();
  runApp(const ShuttleTrackApp());
}
