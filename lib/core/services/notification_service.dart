// Notification Service - Handles local notification scheduling for task reminders.
// Schedules notifications: on creation, 30 minutes before due, and at due time.

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

    try {
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

      final result = await _plugin.initialize(settings: settings);
      debugPrint('🔔 Notification plugin initialized: $result');

      // Request notification permission on Android 13+
      if (Platform.isAndroid) {
        final androidPlugin = _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        if (androidPlugin != null) {
          final granted = await androidPlugin.requestNotificationsPermission();
          debugPrint('🔔 Notification permission granted: $granted');

          // Request exact alarm permission (Android 12+)
          final exactAlarmGranted = await androidPlugin
              .requestExactAlarmsPermission();
          debugPrint('🔔 Exact alarm permission granted: $exactAlarmGranted');
        }
      }

      _initialized = true;
      debugPrint('✅ NotificationService fully initialized');
    } catch (e, stack) {
      debugPrint('❌ NotificationService init failed: $e');
      debugPrint('Stack: $stack');
      // Still mark as initialized to prevent infinite retry loops
      // Individual notification calls will handle their own errors
      _initialized = true;
    }
  }

  /// Ensure the service is initialized before any operation.
  Future<bool> _ensureInitialized() async {
    if (!_initialized) {
      await init();
    }
    return _initialized;
  }

  // ── Notification Details ─────────────────────────────────────

  static const _androidDetails = AndroidNotificationDetails(
    'task_reminders',
    'Task Reminders',
    channelDescription: 'Reminders for upcoming task due dates',
    importance: Importance.high,
    priority: Priority.high,
    icon: '@mipmap/ic_launcher',
    enableVibration: true,
    playSound: true,
  );

  static const _iosDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );

  static const _notificationDetails = NotificationDetails(
    android: _androidDetails,
    iOS: _iosDetails,
  );

  // ── Public API ───────────────────────────────────────────────

  /// Schedule reminder notifications for a task:
  /// 1) 30 minutes before due date
  /// 2) At the exact due time
  Future<void> scheduleTaskReminder({
    required String taskId,
    required String title,
    required DateTime dueDate,
  }) async {
    if (!await _ensureInitialized()) return;

    // Cancel any existing reminders for this task first
    await cancelTaskReminder(taskId);

    final now = DateTime.now();
    final idBase = taskId.hashCode.abs();

    // 1) Schedule 30-minute-before reminder
    final reminderTime = dueDate.subtract(const Duration(minutes: 30));
    if (reminderTime.isAfter(now)) {
      try {
        await _plugin.zonedSchedule(
          id: idBase,
          title: '⏰ Task Reminder',
          body: '"$title" is due in 30 minutes',
          scheduledDate: tz.TZDateTime.from(reminderTime, tz.local),
          notificationDetails: _notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
        debugPrint(
          '🔔 30-min reminder for "$title" scheduled at $reminderTime',
        );
      } catch (e) {
        debugPrint('⚠️ Failed to schedule 30-min reminder: $e');
      }
    }

    // 2) Schedule at-due-time notification
    if (dueDate.isAfter(now)) {
      try {
        await _plugin.zonedSchedule(
          id: idBase + 1,
          title: '📋 Task Due Now!',
          body: '"$title" is due right now',
          scheduledDate: tz.TZDateTime.from(dueDate, tz.local),
          notificationDetails: _notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
        debugPrint(
          '🔔 Due-time notification for "$title" scheduled at $dueDate',
        );
      } catch (e) {
        debugPrint('⚠️ Failed to schedule due-time notification: $e');
      }
    }
  }

  /// Show an immediate notification (used for task creation confirmation).
  Future<void> showImmediate({
    required String title,
    required String body,
  }) async {
    if (!await _ensureInitialized()) return;

    try {
      await _plugin.show(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: title,
        body: body,
        notificationDetails: _notificationDetails,
      );
      debugPrint('🔔 Immediate notification shown: $title');
    } catch (e) {
      debugPrint('⚠️ Failed to show immediate notification: $e');
    }
  }

  /// Cancel all reminders for a specific task (both 30-min and due-time).
  Future<void> cancelTaskReminder(String taskId) async {
    final idBase = taskId.hashCode.abs();
    try {
      await _plugin.cancel(id: idBase);
      await _plugin.cancel(id: idBase + 1);
    } catch (e) {
      debugPrint('⚠️ Failed to cancel notification: $e');
    }
  }

  /// Cancel all scheduled reminders.
  Future<void> cancelAllReminders() async {
    try {
      await _plugin.cancelAll();
    } catch (e) {
      debugPrint('⚠️ Failed to cancel all notifications: $e');
    }
  }
}
