// Notification Service - Handles local notification scheduling for task reminders.
// Schedules a notification 30 minutes before a task's due date.

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Initialize the notification plugin and timezone data.
  Future<void> init() async {
    if (_initialized) return;

    tzdata.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings: settings);

    // Request notification permission on Android 13+
    if (Platform.isAndroid) {
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidPlugin != null) {
        await androidPlugin.requestNotificationsPermission();
      }
    }

    _initialized = true;
  }

  /// Schedule reminder notifications for a task:
  /// 1) 30 minutes before due date
  /// 2) At the exact due time
  Future<void> scheduleTaskReminder({
    required String taskId,
    required String title,
    required DateTime dueDate,
  }) async {
    if (!_initialized) await init();

    const androidDetails = AndroidNotificationDetails(
      'task_reminders',
      'Task Reminders',
      channelDescription: 'Reminders for upcoming task due dates',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Cancel any existing reminders for this task
    await _plugin.cancel(id: taskId.hashCode);
    await _plugin.cancel(id: taskId.hashCode + 1);

    final now = DateTime.now();

    // 1) Schedule 30-minute-before reminder
    final reminderTime = dueDate.subtract(const Duration(minutes: 30));
    if (reminderTime.isAfter(now)) {
      await _plugin.zonedSchedule(
        id: taskId.hashCode,
        title: '⏰ Task Reminder',
        body: '$title is due in 30 minutes',
        scheduledDate: tz.TZDateTime.from(reminderTime, tz.local),
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
      debugPrint('🔔 30-min reminder for "$title" scheduled');
    }

    // 2) Schedule at-due-time notification
    if (dueDate.isAfter(now)) {
      await _plugin.zonedSchedule(
        id: taskId.hashCode + 1,
        title: '📋 Task Due Now!',
        body: '$title is due right now',
        scheduledDate: tz.TZDateTime.from(dueDate, tz.local),
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
      debugPrint('🔔 Due-time notification for "$title" scheduled');
    }
  }

  /// Show an immediate notification (used for confirmation feedback).
  Future<void> showImmediate({
    required String title,
    required String body,
  }) async {
    if (!_initialized) await init();

    const androidDetails = AndroidNotificationDetails(
      'task_reminders',
      'Task Reminders',
      channelDescription: 'Reminders for upcoming task due dates',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }

  /// Cancel all reminders for a specific task (both 30-min and due-time).
  Future<void> cancelTaskReminder(String taskId) async {
    await _plugin.cancel(id: taskId.hashCode);
    await _plugin.cancel(id: taskId.hashCode + 1);
  }

  /// Cancel all scheduled reminders.
  Future<void> cancelAllReminders() async {
    await _plugin.cancelAll();
  }
}
