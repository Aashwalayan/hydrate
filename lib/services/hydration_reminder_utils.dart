import 'package:flutter/material.dart';

import '../screens/home/alarm_screen.dart';
import '../services/hydration_service.dart';

class NextHydrationReminder {
  const NextHydrationReminder({
    required this.time,
    required this.scheduledAt,
    required this.secondsRemaining,
    required this.upcomingCount,
    this.amountMl,
  });

  final TimeOfDay time;
  final DateTime scheduledAt;
  final int secondsRemaining;
  final int upcomingCount;
  final int? amountMl;
}

DateTime reminderOccurrence(TimeOfDay time, {DateTime? now}) {
  final current = now ?? DateTime.now();

  var occurrence = DateTime(
    current.year,
    current.month,
    current.day,
    time.hour,
    time.minute,
  );

  if (!occurrence.isAfter(current)) {
    occurrence = occurrence.add(const Duration(days: 1));
  }

  return occurrence;
}

NextHydrationReminder? calculateNextHydrationReminder({
  required HydrationAlarm alarm,
  required DailyHydration? today,
  DateTime? now,
}) {
  if (!alarm.enabled || alarm.reminderTimes.isEmpty) {
    return null;
  }

  final current = now ?? DateTime.now();

  final occurrences = alarm.reminderTimes
      .map((time) => (
            time: time,
            occurrence: reminderOccurrence(time, now: current),
          ))
      .toList()
    ..sort((a, b) => a.occurrence.compareTo(b.occurrence));

  final next = occurrences.first;

  // Only reminders that are still upcoming TODAY count toward
  // the water distribution.
  final upcomingToday = occurrences
      .where(
        (item) =>
            item.occurrence.year == current.year &&
            item.occurrence.month == current.month &&
            item.occurrence.day == current.day,
      )
      .toList();

  int? amountMl;

  if (today != null && today.intakeMl < today.goalMl) {
    final remaining = today.goalMl - today.intakeMl;

    final divisor = upcomingToday.isNotEmpty
        ? upcomingToday.length
        : alarm.reminderTimes.length;

    final rawPerReminder = remaining / divisor;

    var rounded = (rawPerReminder / 50).round() * 50;

    if (rounded == 0 && remaining > 0) {
      rounded = remaining;
    }

    amountMl = rounded;
  }

  return NextHydrationReminder(
    time: next.time,
    scheduledAt: next.occurrence,
    secondsRemaining: next.occurrence.difference(current).inSeconds,
    upcomingCount: upcomingToday.length,
    amountMl: amountMl,
  );
}