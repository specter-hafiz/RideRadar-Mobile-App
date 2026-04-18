import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _plugin.initialize(settings);
  }

  Future<void> showStopAlert({
    required String shuttleName,
    required String stopName,
    required String routeName,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'shuttle_stop_alerts',
      'Shuttle Stop Alerts',
      channelDescription: 'Alerts when a shuttle approaches a bus stop',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );
    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      '$shuttleName approaching $stopName',
      '$shuttleName is arriving at $stopName on the $routeName route.',
      details,
    );
  }
}
