import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class HydrationResponse {
  const HydrationResponse({
    required this.success,
    required this.message,
  });

  final bool success;
  final String message;
}

class HydrationEntry {
  const HydrationEntry({
    required this.amountMl,
    required this.timestamp,
  });

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
            (entry) => HydrationEntry.fromJson(
              entry as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }
}

class HydrationService {
  static const String baseUrl =
      'https://hydrate-vor8.onrender.com/api/hydration';

  // -------------------------------------------------------------------------
  // Authentication
  // -------------------------------------------------------------------------

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

  // -------------------------------------------------------------------------
  // Date
  // -------------------------------------------------------------------------

  String _localDate() {
    final now = DateTime.now();

    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  // -------------------------------------------------------------------------
  // Hydration Settings
  // -------------------------------------------------------------------------

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

  // -------------------------------------------------------------------------
  // Get Today's Hydration
  // -------------------------------------------------------------------------

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
      throw Exception(
        data['message'] ?? 'Failed to load today\'s hydration.',
      );
    }

    return DailyHydration.fromJson(data);
  }

  // -------------------------------------------------------------------------
  // Add Water
  // -------------------------------------------------------------------------

  Future<DailyHydration> addWater(int amountMl) async {
    final headers = await _authHeaders();

    if (headers == null) {
      throw Exception('Authentication token not found.');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/water'),
      headers: headers,
      body: jsonEncode({
        'amountMl': amountMl,
        'date': _localDate(),
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 201) {
      throw Exception(
        data['message'] ?? 'Failed to add water.',
      );
    }

    return DailyHydration.fromJson(
      data['daily'] as Map<String, dynamic>,
    );
  }

  // -------------------------------------------------------------------------
  // Get Hydration History
  // -------------------------------------------------------------------------

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
      throw Exception(
        data['message'] ?? 'Failed to load hydration history.',
      );
    }

    return (data as List<dynamic>)
        .map(
          (day) => DailyHydration.fromJson(
            day as Map<String, dynamic>,
          ),
        )
        .toList();
  }
}