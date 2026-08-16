import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'dart:developer' as developer;

class NotificationService {
  NotificationService._();

  Future<void> testNotification() async {
    developer.log('FULL SCREEN TEST: scheduling in 10 seconds');

    final now = tz.TZDateTime.now(tz.local);
    final scheduled = now.add(const Duration(seconds: 10));

    await _notifications.zonedSchedule(
      id: 999,
      title: 'Hydrate Alarm',
      body: 'This is a full-screen alarm test.',
      scheduledDate: scheduled,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'hydration_fullscreen_test',
          'Hydration Full Screen Test',
          channelDescription: 'Testing Hydrate alarm full-screen behavior',
          importance: Importance.max,
          priority: Priority.max,
          playSound: true,
          enableVibration: true,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );

    developer.log('FULL SCREEN TEST: scheduled successfully');
  }

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone database.
    tz.initializeTimeZones();

    // Get the device's local timezone.
    final timezoneInfo = await FlutterTimezone.getLocalTimezone();

    final timezoneName = timezoneInfo.identifier == 'Asia/Calcutta'
        ? 'Asia/Kolkata'
        : timezoneInfo.identifier;

    tz.setLocalLocation(tz.getLocation(timezoneName));

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const initializationSettings = InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.requestExactAlarmsPermission();
    await androidPlugin?.requestFullScreenIntentPermission();

    _initialized = true;
  }

  void _onNotificationTapped(NotificationResponse response) {
    // We'll connect this to AlarmRingingScreen later.
  }

  Future<void> scheduleTestAlarm() async {
    await initialize();

    final scheduledTime = tz.TZDateTime.now(
      tz.local,
    ).add(const Duration(seconds: 10));

    const notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'hydration_alarms',
        'Hydration Alarms',
        channelDescription: 'Hydration reminder alarms',
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        fullScreenIntent: true,
      ),
    );

    await _notifications.zonedSchedule(
      id: 999,
      title: 'Time to hydrate',
      body: 'Drink some water.',
      scheduledDate: scheduledTime,
      notificationDetails: notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancel(int id) async {
    await _notifications.cancel(id: id);
  }

  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }
}
