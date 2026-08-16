import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class HydrationResponse {
  const HydrationResponse({required this.success, required this.message});

  final bool success;
  final String message;
}

class HydrationEntry {
  const HydrationEntry({required this.amountMl, required this.timestamp});

  final int amountMl;
  final DateTime timestamp;

  factory HydrationEntry.fromJson(Map<String, dynamic> json) {
    return HydrationEntry(
      amountMl: (json['amountMl'] as num).toInt(),
      timestamp: DateTime.parse(json['timestamp'] as String).toLocal(),
    );
  }
}

class DailyHydration {
  const DailyHydration({
    required this.date,
    required this.goalMl,
    required this.intakeMl,
    required this.completionPercent,
    required this.level,
    required this.entries,
  });

  final String date;
  final int goalMl;
  final int intakeMl;
  final int completionPercent;
  final int level;
  final List<HydrationEntry> entries;

  factory DailyHydration.fromJson(Map<String, dynamic> json) {
    final entriesJson = json['entries'] as List<dynamic>? ?? [];

    return DailyHydration(
      date: json['date'] as String,
      goalMl: (json['goalMl'] as num).toInt(),
      intakeMl: (json['intakeMl'] as num).toInt(),
      completionPercent: (json['completionPercent'] as num).toInt(),
      level: (json['level'] as num).toInt(),
      entries: entriesJson
          .map(
            (entry) => HydrationEntry.fromJson(entry as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'goalMl': goalMl,
      'intakeMl': intakeMl,
      'completionPercent': completionPercent,
      'level': level,
      'entries': entries
          .map(
            (entry) => {
              'amountMl': entry.amountMl,
              'timestamp': entry.timestamp.toIso8601String(),
            },
          )
          .toList(),
    };
  }
}

class HydrationService {
  static const String baseUrl =
      'https://hydrate-vor8.onrender.com/api/hydration';

  static const String _todayCacheKey = 'hydration_today';

  Future<void> _cacheToday(DailyHydration today) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_todayCacheKey, jsonEncode(today.toJson()));
  }

  Future<void> updateCachedGoal(int goalMl) async {
    final today = await getCachedToday();

    if (today == null) return;

    final completionPercent = goalMl <= 0
        ? 0
        : ((today.intakeMl / goalMl) * 100).round();

    final updated = DailyHydration(
      date: today.date,
      goalMl: goalMl,
      intakeMl: today.intakeMl,
      completionPercent: completionPercent,
      level: today.level,
      entries: today.entries,
    );

    await _cacheToday(updated);
  }

  Future<DailyHydration?> _getCachedToday() async {
    final prefs = await SharedPreferences.getInstance();

    final cached = prefs.getString(_todayCacheKey);

    if (cached == null) return null;

    try {
      return DailyHydration.fromJson(
        jsonDecode(cached) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, String>?> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null || token.isEmpty) {
      return null;
    }

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  String _localDate() {
    final now = DateTime.now();

    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  Future<HydrationResponse> saveSettings({
    required int dailyGoalMl,
    required bool enabled,
    required Duration interval,
    required String startTime,
    required String endTime,
  }) async {
    try {
      final headers = await _authHeaders();

      if (headers == null) {
        return const HydrationResponse(
          success: false,
          message: 'Authentication token not found.',
        );
      }

      final response = await http.post(
        Uri.parse('$baseUrl/settings'),
        headers: headers,
        body: jsonEncode({
          'dailyGoalMl': dailyGoalMl,
          'reminders': {
            'enabled': enabled,
            'intervalMinutes': interval.inMinutes,
            'startTime': startTime,
            'endTime': endTime,
          },
        }),
      );

      final data = jsonDecode(response.body);

      return HydrationResponse(
        success: response.statusCode == 200,
        message: data['message'] ?? 'Failed to save hydration settings.',
      );
    } catch (e) {
      return const HydrationResponse(
        success: false,
        message: 'Unable to connect to the server.',
      );
    }
  }

  Future<DailyHydration?> getCachedToday() async {
    final cached = await _getCachedToday();

    if (cached == null) return null;

    if (cached.date != _localDate()) {
      return null;
    }

    return cached;
  }

  Future<DailyHydration> getToday() async {
    final headers = await _authHeaders();

    if (headers == null) {
      throw Exception('Authentication token not found.');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/today?date=${_localDate()}'),
      headers: headers,
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to load today\'s hydration.');
    }

    final today = DailyHydration.fromJson(data);

    await _cacheToday(today);

    return today;
  }

  Future<DailyHydration> addWater(int amountMl) async {
    final headers = await _authHeaders();

    if (headers == null) {
      throw Exception('Authentication token not found.');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/water'),
      headers: headers,
      body: jsonEncode({'amountMl': amountMl, 'date': _localDate()}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 201) {
      throw Exception(data['message'] ?? 'Failed to add water.');
    }

    final today = DailyHydration.fromJson(
      data['daily'] as Map<String, dynamic>,
    );

    await _cacheToday(today);

    return today;
  }

  Future<HydrationResponse> updateGoal(int goalMl) async {
    try {
      final headers = await _authHeaders();

      if (headers == null) {
        return const HydrationResponse(
          success: false,
          message: 'Authentication token not found.',
        );
      }

      final response = await http.patch(
        Uri.parse('$baseUrl/goal'),
        headers: headers,
        body: jsonEncode({'dailyGoalMl': goalMl}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode != 200) {
        return HydrationResponse(
          success: false,
          message: data['message'] ?? 'Failed to update hydration goal.',
        );
      }

      // The backend returns today's updated daily record when one exists.
      if (data['daily'] != null) {
        final daily = DailyHydration.fromJson(
          data['daily'] as Map<String, dynamic>,
        );

        await _cacheToday(daily);
      } else {
        // No daily record exists yet.
        // Preserve the existing cached intake and update only the goal.
        await updateCachedGoal(goalMl);
      }

      return HydrationResponse(
        success: true,
        message: data['message'] ?? 'Hydration goal updated successfully.',
      );
    } catch (e) {
      return const HydrationResponse(
        success: false,
        message: 'Unable to connect to the server.',
      );
    }
  }

  Future<List<DailyHydration>> getHistory() async {
    final headers = await _authHeaders();

    if (headers == null) {
      throw Exception('Authentication token not found.');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/history'),
      headers: headers,
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to load hydration history.');
    }

    return (data as List<dynamic>)
        .map((day) => DailyHydration.fromJson(day as Map<String, dynamic>))
        .toList();
  }
}
