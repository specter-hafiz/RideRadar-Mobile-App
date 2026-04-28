import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shuttletrack/app.dart';
import 'package:shuttletrack/core/services/directions_service.dart';
import 'package:shuttletrack/core/services/notification_service.dart';
import 'package:shuttletrack/data/datasources/mock_tracking_datasource.dart';
import 'package:shuttletrack/di/injection_container.dart';
import 'package:shuttletrack/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initDependencies();
  await sl<NotificationService>().initialize();
  final directionsService = DirectionsService(
    apiKey: 'AIzaSyDhYjxSdHgB72tvcOyp36QBf_SY4dKW7Tg',
  );
  final trackingDatasource = MockTrackingDatasource(
    directionsService: directionsService,
  );
  await trackingDatasource.init();
  runApp(const ShuttleTrackApp());
}
