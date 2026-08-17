import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'notification_service.dart';

/// The minimal information needed to render a firing alarm — deliberately
/// much smaller than the full `HydrationAlarm` config model, since the
/// ringing screen only needs to know what fired, not how it was configured.
@immutable
class ActiveAlarm {
  const ActiveAlarm({
    required this.id,
    required this.label,
    required this.scheduledTime,
  });

  final int id;
  final String label;
  final DateTime scheduledTime;

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'scheduledTime': scheduledTime.toIso8601String(),
      };

  factory ActiveAlarm.fromJson(Map<String, dynamic> json) => ActiveAlarm(
        id: json['id'] as int,
        label: json['label'] as String,
        scheduledTime: DateTime.parse(json['scheduledTime'] as String),
      );

  /// Encodes this alarm into the string carried as a notification payload.
  String encode() => jsonEncode(toJson());

  /// Decodes a notification payload back into an [ActiveAlarm]. Returns
  /// `null` for anything that isn't a valid encoded alarm — e.g. a
  /// notification payload from some other feature, or a malformed/legacy
  /// payload — rather than throwing.
  static ActiveAlarm? decode(String? payload) {
    if (payload == null || payload.isEmpty) return null;
    try {
      final map = jsonDecode(payload) as Map<String, dynamic>;
      return ActiveAlarm.fromJson(map);
    } catch (_) {
      return null;
    }
  }
}

/// Sits between the alarm configuration UI (`alarm_screen.dart`),
/// `NotificationService`, and `AlarmRingingScreen`.
///
/// `AlarmRingingScreen` should only ever call [dismiss] / [snooze] here —
/// it should never talk to `NotificationService` directly, and it should
/// never contain scheduling logic itself.
class AlarmService {
  AlarmService._();

  static final AlarmService instance = AlarmService._();

  static const Duration defaultSnoozeDuration = Duration(minutes: 10);

  /// The alarm currently believed to be ringing, if any. `AlarmRingingScreen`
  /// doesn't need to read this directly (it's constructed with the alarm
  /// data it needs), but other parts of the app can observe it if useful —
  /// e.g. to avoid double-showing the ringing screen.
  final ValueNotifier<ActiveAlarm?> activeAlarm = ValueNotifier(null);

  /// Set once by the app root (see `main.dart`). Called whenever an alarm
  /// should be shown to the user. Kept as a plain callback rather than a
  /// direct import of Navigator/MaterialPageRoute so this service has zero
  /// UI dependencies.
  void Function(ActiveAlarm alarm)? onAlarmTriggered;

  /// Schedules a single hydration alarm. [id] should match the id used for
  /// the underlying `HydrationAlarm` reminder slot so cancelling/rescheduling
  /// stays 1:1 with the configuration screen.
  Future<void> scheduleAlarm({
    required int id,
    required String label,
    required DateTime scheduledTime,
  }) async {
    final alarm = ActiveAlarm(id: id, label: label, scheduledTime: scheduledTime);
    await NotificationService.instance.scheduleAlarmNotification(
      id: id,
      title: 'Time to hydrate',
      body: label,
      scheduledTime: scheduledTime,
      payload: alarm.encode(),
    );
  }

  Future<void> cancelAlarm(int id) async {
    await NotificationService.instance.cancel(id);
    if (activeAlarm.value?.id == id) {
      activeAlarm.value = null;
    }
  }

  /// Called by `AlarmRingingScreen` when the user taps Dismiss. Cancels the
  /// notification and clears the active-alarm state. Sound/vibration
  /// stopping is the ringing screen's own responsibility (it owns those
  /// timers), not this service's.
  Future<void> dismiss(int id) => cancelAlarm(id);

  /// Called by `AlarmRingingScreen` when the user taps Snooze. Cancels the
  /// current notification and reschedules the same alarm [duration] later.
  /// Defaults to 10 minutes; pass a different value once this is backed by
  /// a real user setting.
  Future<void> snooze(
    ActiveAlarm alarm, {
    Duration duration = defaultSnoozeDuration,
  }) async {
    activeAlarm.value = null;
    await NotificationService.instance.cancel(alarm.id);
    final newTime = DateTime.now().add(duration);
    await scheduleAlarm(id: alarm.id, label: alarm.label, scheduledTime: newTime);
  }

  /// Called by [NotificationService] whenever a notification response
  /// arrives while the Dart isolate is already alive (foreground, or
  /// background with the engine still running). Decodes the payload and,
  /// if it's a valid alarm payload, hands off to [onAlarmTriggered].
  ///
  /// This does NOT cover the case where the app process itself was
  /// launched fresh by the notification — see
  /// `NotificationService.getLaunchDetails()`, checked once at startup in
  /// `main.dart`, for that case.
  void handleNotificationResponse(String? payload) {
    final alarm = ActiveAlarm.decode(payload);
    if (alarm == null) return;
    activeAlarm.value = alarm;
    onAlarmTriggered?.call(alarm);
  }
}