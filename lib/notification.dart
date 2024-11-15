import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Initialize notifications
  static Future<void> initialize() async {
    final initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon'); // Icon in drawable folder

    final initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  // Show the notification
  static Future<void> showNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'default_channel_id', 
      'Default Channel', 
      importance: Importance.high, 
      priority: Priority.high,
    );
    const notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      0, // Notification ID
      'Unused Draft', // Title
      'You haven\'t used any drafts in the last 5 minutes.', // Body
      notificationDetails,
    );
  }
}