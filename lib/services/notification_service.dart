import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettings = InitializationSettings(android: androidSettings);
    await _notificationsPlugin.initialize(initializationSettings);
  }

  Future<void> showNotification(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'pomodoro_channel',
      'Pomodoro Notifications',
      importance: Importance.high,
      priority: Priority.high,
    );
    const notificationDetails = NotificationDetails(android: androidDetails);
    await _notificationsPlugin.show(0, title, body, notificationDetails);
  }

  void showSyncNotification({
    required bool success,
    String? message,
  }) async {
    await _notificationsPlugin.show(
      0,
      success ? 'Синхронизация успешна' : 'Ошибка синхронизации',
      message ?? (success ? 'Данные успешно синхронизированы' : 'Не удалось синхронизировать данные'),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'sync_channel',
          'Синхронизация',
          channelDescription: 'Уведомления о синхронизации',
          importance: Importance.low,
          priority: Priority.low,
        ),
      ),
    );
  }
}