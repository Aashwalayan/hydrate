import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;


/// Runs in a separate background isolate when a notification is responded
/// to (e.g. an action button tap) while the app is backgrounded/terminated
/// and Android does NOT launch a fresh Activity for it. This isolate has no
/// access to the running app's state, navigatorKey, or any service
/// singletons living in the main isolate — it can only do isolate-local
/// work (logging, or in the future, writing to local storage).
///
/// Full-screen hydration alarms don't rely on this: they launch the app's
/// MainActivity directly (see the `showWhenLocked`/`turnScreenOn` manifest
/// flags), which runs a normal `main()` cold start. That cold-start path is
/// handled in `main.dart` via [NotificationService.getLaunchDetails].
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  
}

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Set by the app root (see `main.dart`) so foreground / background-but-
  /// isolate-alive notification taps can be handed off to [AlarmService]
  /// without this service knowing anything about alarms or UI.
  void Function(String? payload)? onResponse;

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
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
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
    onResponse?.call(response.payload);
  }

  /// Whether this app process was launched by the user tapping — or the
  /// system full-screen-launching — a notification, and if so, the details
  /// (including payload) it carried.
  ///
  /// Check this once at startup, right after [initialize]. It's the only
  /// way to catch the terminated-app case: [onDidReceiveNotificationResponse]
  /// only fires for an isolate that was already running.
  Future<NotificationAppLaunchDetails?> getLaunchDetails() {
    return _notifications.getNotificationAppLaunchDetails();
  }

  /// Schedules a single hydration alarm notification with a full-screen
  /// intent, carrying [payload] (an encoded `ActiveAlarm` from
  /// `AlarmService`) so the app can reconstruct which alarm fired without
  /// needing the full `HydrationAlarm` config object.
  ///
  /// This is the method `AlarmService` calls — `alarm_screen.dart` and
  /// `AlarmRingingScreen` should never call this (or any other method on
  /// this service) directly.
  Future<void> scheduleAlarmNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    required String payload,
  }) async {
    await initialize();

    final scheduled = tz.TZDateTime.from(scheduledTime, tz.local);

    await _notifications.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduled,
      payload: payload,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'hydration_alarms',
          'Hydration Alarms',
          channelDescription: 'Hydration reminder alarms',
          importance: Importance.max,
          priority: Priority.max,
          playSound: true,
          enableVibration: true,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,
          audioAttributesUsage: AudioAttributesUsage.alarm,
        ),
      ),
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