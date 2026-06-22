import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../screens/history_page.dart';
import 'notification_repository.dart';

class ReminderService {
  ReminderService._();

  static final navigatorKey = GlobalKey<NavigatorState>();
  static final _notifications = FlutterLocalNotificationsPlugin();
  static final _repo = NotificationRepository();

  static const _firstReminderId = 2300;
  static const _secondReminderId = 2330;
  static const _historyPayload = "open_history";
  static bool _shouldOpenHistoryOnStart = false;

  static Future<void> initialize() async {
    tz.initializeTimeZones();

    try {
      final timeZoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneInfo.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }

    const androidSettings = AndroidInitializationSettings(
      "@mipmap/ic_launcher",
    );
    const initializationSettings = InitializationSettings(
      android: androidSettings,
    );

    final launchDetails = await _notifications
        .getNotificationAppLaunchDetails();
    _shouldOpenHistoryOnStart =
        launchDetails?.didNotificationLaunchApp == true &&
        launchDetails?.notificationResponse?.payload == _historyPayload;

    await _notifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: _handleNotificationTap,
    );

    await _requestAndroidPermissions();
    await refreshScheduleSafely();
  }

  static void openHistoryIfNotificationLaunchedApp() {
    if (!_shouldOpenHistoryOnStart) {
      return;
    }

    _shouldOpenHistoryOnStart = false;
    _openHistory();
  }

  static Future<void> refreshSchedule() async {
    final pendingCount = await _repo.pendingCategorizationCount();

    await _notifications.cancel(id: _firstReminderId);
    await _notifications.cancel(id: _secondReminderId);

    if (pendingCount == 0) {
      return;
    }

    await _scheduleDailyReminder(
      id: _firstReminderId,
      hour: 23,
      minute: 0,
      title: "Review Today's Expenses",
      body:
          "You have uncategorized transactions waiting. Tap to organize them.",
    );

    await _scheduleDailyReminder(
      id: _secondReminderId,
      hour: 23,
      minute: 30,
      title: "Don't Forget Your Expense Review",
      body:
          "You still have uncategorized transactions. Spend a minute categorizing them.",
    );
  }

  static Future<void> refreshScheduleSafely() async {
    try {
      await refreshSchedule();
    } catch (error) {
      debugPrint("Failed to refresh reminder schedule: $error");
    }
  }

  static Future<void> _scheduleDailyReminder({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    await _notifications.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: _nextReminderTime(hour, minute),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          "expense_review_reminders",
          "Expense Review Reminders",
          channelDescription:
              "Daily reminders to categorize reviewed transactions.",
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      payload: _historyPayload,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static tz.TZDateTime _nextReminderTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return scheduled;
  }

  static Future<void> _requestAndroidPermissions() async {
    final androidImplementation = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidImplementation?.requestNotificationsPermission();
    await androidImplementation?.requestExactAlarmsPermission();
  }

  static void _handleNotificationTap(NotificationResponse response) {
    if (response.payload == _historyPayload) {
      _openHistory();
    }
  }

  static void _openHistory() {
    final navigator = navigatorKey.currentState;

    if (navigator == null) {
      _shouldOpenHistoryOnStart = true;
      return;
    }

    navigator.push(MaterialPageRoute(builder: (_) => const HistoryPage()));
  }
}
