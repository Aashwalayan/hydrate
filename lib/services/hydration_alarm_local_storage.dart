import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../screens/home/alarm_screen.dart';

/// Local-first, on-device persistence for the user's single hydration
/// alarm.
///
/// Deliberately separate from `HydrationAlarmService`:
/// - This service = immediate device state. Always available, never
///   touches the network, never waits on Render.
/// - `HydrationAlarmService` = backend (MongoDB) synchronization, which
///   can be slow or briefly unavailable and must never block the UI.
///
/// `AlarmScreen` reads/writes through this service first, on every
/// operation, before ever talking to the backend.
///
/// NOTE: this imports `HydrationAlarm` / `AlarmScheduleType` / `AlarmTone`
/// from `alarm_screen.dart`, since that's where those types currently
/// live (they were never split into their own model file). If you later
/// extract them into e.g. `lib/models/hydration_alarm.dart`, this is the
/// only import that needs to change.
class HydrationAlarmLocalStorage {
  static const _key = 'hydrate.local_alarm.v1';

  /// Loads the persisted alarm, or `null` if none has been saved yet (or
  /// the stored data is corrupt/from an incompatible older model shape —
  /// this never throws, it just falls back to "no alarm").
  Future<HydrationAlarm?> loadAlarm() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;

    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return _fromJson(map);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveAlarm(HydrationAlarm alarm) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(_toJson(alarm)));
  }

  Future<void> deleteAlarm() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  // --- Serialization ---------------------------------------------------

  Map<String, dynamic> _toJson(HydrationAlarm alarm) {
    return {
      'id': alarm.id,
      'label': alarm.label,
      'scheduleType': alarm.scheduleType.name,
      'reminderTimes': alarm.reminderTimes.map(_timeToJson).toList(),
      'enabled': alarm.enabled,
      'startTime':
          alarm.startTime != null ? _timeToJson(alarm.startTime!) : null,
      'endTime': alarm.endTime != null ? _timeToJson(alarm.endTime!) : null,
      'intervalMinutes': alarm.intervalMinutes,
      'tone': alarm.tone.name,
    };
  }

  HydrationAlarm _fromJson(Map<String, dynamic> json) {
    return HydrationAlarm(
      id: json['id'] as String,
      label: json['label'] as String,
      scheduleType: AlarmScheduleType.values.firstWhere(
        (t) => t.name == json['scheduleType'],
        orElse: () => AlarmScheduleType.equalIntervals,
      ),
      reminderTimes: (json['reminderTimes'] as List)
          .map((t) => _timeFromJson(t as Map<String, dynamic>))
          .toList(),
      enabled: json['enabled'] as bool,
      startTime: json['startTime'] != null
          ? _timeFromJson(json['startTime'] as Map<String, dynamic>)
          : null,
      endTime: json['endTime'] != null
          ? _timeFromJson(json['endTime'] as Map<String, dynamic>)
          : null,
      intervalMinutes: json['intervalMinutes'] as int?,
      tone: AlarmTone.values.firstWhere(
        (t) => t.name == json['tone'],
        orElse: () => AlarmTone.alarmtone1,
      ),
    );
  }

  Map<String, dynamic> _timeToJson(TimeOfDay t) => {'h': t.hour, 'm': t.minute};

  TimeOfDay _timeFromJson(Map<String, dynamic> json) =>
      TimeOfDay(hour: json['h'] as int, minute: json['m'] as int);
}