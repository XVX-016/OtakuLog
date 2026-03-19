import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class ReminderService {
  static const int notificationId = 4401;

  final FlutterLocalNotificationsPlugin _plugin;

  ReminderService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    try {
      await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.initialize(settings: android);
    } catch (error) {
      debugPrint('Reminder init failed: $error');
    }
  }

  Future<void> cancelReminder() async {
    try {
      await _plugin.cancel(id: notificationId);
    } catch (error) {
      debugPrint('Reminder cancel failed: $error');
    }
  }

  Future<void> scheduleReminder({
    required DateTime scheduledFor,
    required String title,
    required String body,
  }) async {
    try {
      final when = scheduledFor.isBefore(DateTime.now())
          ? DateTime.now().add(const Duration(minutes: 1))
          : scheduledFor;
      await _plugin.zonedSchedule(
        id: notificationId,
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.from(when, tz.local),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'goontwin_retention',
            'Retention reminders',
            channelDescription: 'Daily GoonTwin reminders',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (error) {
      debugPrint('Reminder schedule failed: $error');
    }
  }
}
