import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
      },
    );

    _initialized = true;
  }

  static Future<void> showNotification() async {
    if (!_initialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      'drafts_channel',
      'Draft Notifications',
      channelDescription: 'Notifications for unused drafts',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notifications.show(
      1,
      'Unused Draft Reminder',
      'You have unfinished drafts waiting for you!',
      notificationDetails,
    );
  }
  
}
