import 'dart:convert';

import 'package:alarm/alarm.dart';
import 'package:flutter/foundation.dart';

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

  final ValueNotifier<ActiveAlarm?> activeAlarm = ValueNotifier<ActiveAlarm?>(
    null,
  );

  void Function(ActiveAlarm alarm)? onAlarmTriggered;

  /// Generates a unique alarm ID for each reminder slot.
  int notificationIdFor(String alarmId, int reminderIndex) {
    final numericId = alarmId.hashCode.abs() & 0x7FFFFFFF;

    return (numericId + reminderIndex) & 0x7FFFFFFF;
  }

  /// Starts listening for alarms fired by the `alarm` package.
  ///
  /// This should be called once during app initialization.
  void initialize() {
    Alarm.ringing.listen((alarmSet) {
      for (final alarm in alarmSet.alarms) {
        _handleRingingAlarm(alarm);
      }
    });
  }

  void _handleRingingAlarm(AlarmSettings alarmSettings) {
    debugPrint(
      'HYDRATE ALARM RINGING: '
      'id=${alarmSettings.id}, '
      'payload=${alarmSettings.payload}',
    );

    final alarm = ActiveAlarm.decode(alarmSettings.payload);

    if (alarm == null) {
      debugPrint('HYDRATE ALARM: payload could not be decoded');
      return;
    }

    activeAlarm.value = alarm;

    debugPrint(
      'HYDRATE ALARM TRIGGERED: '
      'id=${alarm.id}, label=${alarm.label}',
    );

    onAlarmTriggered?.call(alarm);
  }

  /// Schedule every reminder belonging to one HydrationAlarm.
  ///
  /// Each DateTime in [reminderTimes] becomes an independent alarm.
  Future<void> scheduleAlarm({
    required String id,
    required String label,
    required List<DateTime> reminderTimes,
  }) async {
    for (var i = 0; i < reminderTimes.length; i++) {
      final scheduledTime = reminderTimes[i];
      final alarmId = notificationIdFor(id, i);

      final activeAlarm = ActiveAlarm(
        id: alarmId,
        label: label,
        scheduledTime: scheduledTime,
      );

      final settings = AlarmSettings(
        id: alarmId,
        dateTime: scheduledTime,
        assetAudioPath: 'assets/sounds/alarm.mp3',
        loopAudio: true,
        vibrate: true,
        androidFullScreenIntent: true,
        warningNotificationOnKill: false,
        volumeSettings: const VolumeSettings.fixed(volume: 1.0),
        notificationSettings: NotificationSettings(
          title: 'Time to hydrate',
          body: label,
          stopButton: 'Dismiss',
        ),
        payload: activeAlarm.encode(),
      );

      await Alarm.set(alarmSettings: settings);
    }
  }

  /// Cancel all alarm slots belonging to a HydrationAlarm.
  Future<void> cancelAlarm(String id, {required int reminderCount}) async {
    for (var i = 0; i < reminderCount; i++) {
      final alarmId = notificationIdFor(id, i);

      await Alarm.stop(alarmId);

      if (activeAlarm.value?.id == alarmId) {
        activeAlarm.value = null;
      }
    }
  }

  /// Reschedule an edited alarm.
  ///
  /// Old reminder slots are cancelled first, then the new slots are created.
  Future<void> rescheduleAlarm({
    required String id,
    required String label,
    required List<DateTime> oldReminderTimes,
    required List<DateTime> newReminderTimes,
  }) async {
    await cancelAlarm(id, reminderCount: oldReminderTimes.length);

    await scheduleAlarm(id: id, label: label, reminderTimes: newReminderTimes);
  }

  /// Dismiss the currently ringing alarm.
  Future<void> dismiss(int alarmId) async {
    await Alarm.stop(alarmId);

    if (activeAlarm.value?.id == alarmId) {
      activeAlarm.value = null;
    }
  }

  /// Snooze the currently ringing alarm.
  ///
  /// This creates a new one-off alarm and does not modify the
  /// persisted HydrationAlarm schedule.
  Future<void> snooze(
    ActiveAlarm alarm, {
    Duration duration = defaultSnoozeDuration,
  }) async {
    await Alarm.stop(alarm.id);

    activeAlarm.value = null;

    final newTime = DateTime.now().add(duration);

    final snoozedAlarm = ActiveAlarm(
      id: alarm.id,
      label: alarm.label,
      scheduledTime: newTime,
    );

    final settings = AlarmSettings(
      id: alarm.id,
      dateTime: newTime,
      assetAudioPath: 'assets/sounds/alarm.mp3',
      loopAudio: true,
      vibrate: true,
      androidFullScreenIntent: true,
      warningNotificationOnKill: false,
      volumeSettings: const VolumeSettings.fixed(volume: 1.0),
      notificationSettings: NotificationSettings(
        title: 'Time to hydrate',
        body: alarm.label,
        stopButton: 'Dismiss',
      ),
      payload: snoozedAlarm.encode(),
    );

    await Alarm.set(alarmSettings: settings);
  }
}
