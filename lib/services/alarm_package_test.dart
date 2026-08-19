import 'package:alarm/alarm.dart';
import 'package:flutter/foundation.dart';

class AlarmPackageTest {
  static Future<void> scheduleTestAlarm() async {
    final settings = AlarmSettings(
      id: 999999,
      dateTime: DateTime.now().add(const Duration(minutes: 1)),
      assetAudioPath: 'assets/sounds/alarm.mp3',
      loopAudio: true,
      vibrate: true,
      androidFullScreenIntent: true,
      warningNotificationOnKill: false,
      volumeSettings: const VolumeSettings.fixed(
        volume: 1.0,
      ),
      notificationSettings: const NotificationSettings(
        title: 'Hydrate Test',
        body: 'This is a test alarm',
        stopButton: 'Dismiss',
      ),
    );

    await Alarm.set(alarmSettings: settings);

    debugPrint('TEST ALARM SCHEDULED');
  }
}