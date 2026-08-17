import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'notification_service.dart';

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

  String encode() => jsonEncode(toJson());

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

class AlarmService {
  AlarmService._();

  static final AlarmService instance = AlarmService._();

  static const Duration defaultSnoozeDuration = Duration(minutes: 10);

  /// Number of decimal places reserved for the reminder slot.
  ///
  /// Example:
  /// alarm ID 42, slot 0 -> 4200
  /// alarm ID 42, slot 1 -> 4201
  /// alarm ID 42, slot 2 -> 4202
  static const int _notificationIdMultiplier = 100;
  static const MethodChannel _nativeAlarmChannel = MethodChannel(
    'com.hydrate/alarm',
  );

  final ValueNotifier<ActiveAlarm?> activeAlarm = ValueNotifier<ActiveAlarm?>(
    null,
  );

  void Function(ActiveAlarm alarm)? onAlarmTriggered;

  /// Generates the Android notification ID for one reminder slot.
  int notificationIdFor(String alarmId, int reminderIndex) {
    final numericId = alarmId.hashCode.abs() & 0x7FFFFFFF;

    return (numericId + reminderIndex) & 0x7FFFFFFF;
  }

  /// Schedule every reminder belonging to one HydrationAlarm.
  ///
  /// Each DateTime in [reminderTimes] becomes an independent Android
  /// notification.

  Future<void> _scheduleNativeAlarm({
    required int alarmId,
    required String label,
    required DateTime scheduledTime,
  }) async {
    await _nativeAlarmChannel.invokeMethod('scheduleAlarm', {
      'alarmId': alarmId,
      'label': label,
      'scheduledTime': scheduledTime.millisecondsSinceEpoch,
    });
  }

  Future<void> _cancelNativeAlarm(int alarmId) async {
    await _nativeAlarmChannel.invokeMethod('cancelAlarm', {'alarmId': alarmId});
  }

  Future<void> scheduleAlarm({
    required String id,
    required String label,
    required List<DateTime> reminderTimes,
  }) async {
    for (var i = 0; i < reminderTimes.length; i++) {
      final scheduledTime = reminderTimes[i];
      final notificationId = notificationIdFor(id, i);

      await _scheduleNativeAlarm(
        alarmId: notificationId,
        label: label,
        scheduledTime: scheduledTime,
      );
    }
  }

  /// Cancel all notification slots belonging to an alarm.
  ///
  /// [reminderCount] should be the number of reminderTimes currently
  /// belonging to the alarm.
  Future<void> cancelAlarm(String id, {required int reminderCount}) async {
    for (var i = 0; i < reminderCount; i++) {
      final notificationId = notificationIdFor(id, i);
      await _cancelNativeAlarm(notificationId);

      if (activeAlarm.value?.id == notificationId) {
        activeAlarm.value = null;
      }
    }
  }

  /// Reschedule an edited alarm.
  ///
  /// The old reminder notifications are cancelled first, then the new
  /// reminderTimes are scheduled.
  Future<void> rescheduleAlarm({
    required String id,
    required String label,
    required List<DateTime> oldReminderTimes,
    required List<DateTime> newReminderTimes,
  }) async {
    await cancelAlarm(id, reminderCount: oldReminderTimes.length);

    await scheduleAlarm(id: id, label: label, reminderTimes: newReminderTimes);
  }

  /// Dismiss the currently firing notification.
  Future<void> dismiss(int notificationId) async {
    await _cancelNativeAlarm(notificationId);

    if (activeAlarm.value?.id == notificationId) {
      activeAlarm.value = null;
    }
  }

  Future<ActiveAlarm?> getInitialNativeAlarm() async {
    final result = await _nativeAlarmChannel.invokeMethod<dynamic>(
      'getInitialAlarm',
    );

    if (result == null) return null;

    final map = Map<String, dynamic>.from(result as Map);

    final alarmId = map['alarmId'] as int?;
    final label = map['label'] as String?;
    final scheduledTime = map['scheduledTime'] as int?;

    if (alarmId == null || label == null || scheduledTime == null) {
      return null;
    }

    return ActiveAlarm(
      id: alarmId,
      label: label,
      scheduledTime: DateTime.fromMillisecondsSinceEpoch(scheduledTime),
    );
  }

  /// Snooze the currently firing notification.
  ///
  /// Snooze deliberately uses the notification ID of the reminder that
  /// actually fired. It does not modify the persisted HydrationAlarm
  /// schedule.
  Future<void> snooze(
    ActiveAlarm alarm, {
    Duration duration = defaultSnoozeDuration,
  }) async {
    activeAlarm.value = null;

    await NotificationService.instance.cancel(alarm.id);

    final newTime = DateTime.now().add(duration);

    final snoozedAlarm = ActiveAlarm(
      id: alarm.id,
      label: alarm.label,
      scheduledTime: newTime,
    );

    await NotificationService.instance.scheduleAlarmNotification(
      id: alarm.id,
      title: 'Time to hydrate',
      body: alarm.label,
      scheduledTime: newTime,
      payload: snoozedAlarm.encode(),
    );
  }

  /// Called by NotificationService whenever a notification response arrives
  /// while the Dart isolate is alive.
  void handleNotificationResponse(String? payload) {
    final alarm = ActiveAlarm.decode(payload);

    if (alarm == null) return;

    activeAlarm.value = alarm;
    onAlarmTriggered?.call(alarm);
  }
}
