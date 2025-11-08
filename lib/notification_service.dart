import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _notificationService = NotificationService._internal();

  factory NotificationService() {
    return _notificationService;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const LinuxInitializationSettings initializationSettingsLinux = LinuxInitializationSettings(defaultActionName: 'Open');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      linux: initializationSettingsLinux,
    );

    tz.initializeTimeZones();

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> scheduleDeadlineNotification(int id, String title, DateTime deadline) async {
    final now = tz.TZDateTime.now(tz.local);
    final scheduledDate = tz.TZDateTime.from(deadline, tz.local);

    if (scheduledDate.isAfter(now)) {
      // Schedule a notification 1 hour before the deadline
      if (scheduledDate.subtract(const Duration(hours: 1)).isAfter(now)) {
        await _scheduleNotification(
          id: id,
          title: 'Deadline Reminder',
          body: 'The task "$title" is due in 1 hour.',
          scheduledDate: scheduledDate.subtract(const Duration(hours: 1)),
        );
      }

      // Schedule a notification 1 day before the deadline
      if (scheduledDate.subtract(const Duration(days: 1)).isAfter(now)) {
        await _scheduleNotification(
          id: id + 1000, // Use a different ID to avoid collisions
          title: 'Deadline Reminder',
          body: 'The task "$title" is due tomorrow.',
          scheduledDate: scheduledDate.subtract(const Duration(days: 1)),
        );
      }
    }
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
  }) async {
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'deadline_channel_id',
          'Deadline Reminders',
          channelDescription: 'Notifications for task deadlines',
          importance: Importance.max,
          priority: Priority.high,
        ),
        // Add Linux notification details
        linux: LinuxNotificationDetails(),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
    await flutterLocalNotificationsPlugin.cancel(id + 1000); // Also cancel the 1-day reminder
  }
}
