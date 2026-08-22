import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class HydrationAlarmDto {
  const HydrationAlarmDto({
    required this.id,
    required this.label,
    required this.scheduleType,
    required this.reminderTimes,
    required this.enabled,
    this.startTime,
    this.endTime,
    this.intervalMinutes,
    this.tone = 'sound',
  });

  final String id;
  final String label;
  final String scheduleType;
  final List<String> reminderTimes;
  final bool enabled;
  final String? startTime;
  final String? endTime;
  final int? intervalMinutes;
  final String tone;

  factory HydrationAlarmDto.fromJson(Map<String, dynamic> json) {
    return HydrationAlarmDto(
      id: json['_id'] as String,
      label: json['label'] as String,
      scheduleType: json['scheduleType'] as String,
      reminderTimes: (json['reminderTimes'] as List<dynamic>)
          .map((time) => time.toString())
          .toList(),
      enabled: json['enabled'] as bool? ?? true,
      startTime: json['startTime'] as String?,
      endTime: json['endTime'] as String?,
      intervalMinutes: (json['intervalMinutes'] as num?)?.toInt(),
      tone: json['tone'] as String? ?? 'sound',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'scheduleType': scheduleType,
      'reminderTimes': reminderTimes,
      'enabled': enabled,
      'startTime': startTime,
      'endTime': endTime,
      'intervalMinutes': intervalMinutes,
      'tone': tone,
    };
  }
}

class HydrationAlarmResponse {
  const HydrationAlarmResponse({
    required this.success,
    required this.message,
    this.alarm,
  });

  final bool success;
  final String message;
  final HydrationAlarmDto? alarm;
}

class HydrationAlarmService {
  static const String baseUrl =
    'https://hydrate-api-622443979031.asia-south1.run.app/api/hydration/alarms';

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

  Future<List<HydrationAlarmDto>> getAlarms() async {
    final headers = await _authHeaders();

    if (headers == null) {
      throw Exception('Authentication token not found.');
    }

    final response = await http.get(
      Uri.parse(baseUrl),
      headers: headers,
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(
        data['message'] ?? 'Failed to load hydration alarms.',
      );
    }

    return (data as List<dynamic>)
        .map(
          (alarm) => HydrationAlarmDto.fromJson(
            alarm as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<HydrationAlarmResponse> createAlarm({
    required String label,
    required String scheduleType,
    required List<String> reminderTimes,
    required bool enabled,
    String? startTime,
    String? endTime,
    int? intervalMinutes,
    String tone = 'sound',
  }) async {
    try {
      final headers = await _authHeaders();

      if (headers == null) {
        return const HydrationAlarmResponse(
          success: false,
          message: 'Authentication token not found.',
        );
      }

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: headers,
        body: jsonEncode({
          'label': label,
          'scheduleType': scheduleType,
          'reminderTimes': reminderTimes,
          'enabled': enabled,
          'startTime': startTime,
          'endTime': endTime,
          'intervalMinutes': intervalMinutes,
          'tone': tone,
        }),
      );

      final data = jsonDecode(response.body);

      return HydrationAlarmResponse(
        success: response.statusCode == 201,
        message: data['message'] ?? 'Failed to create hydration alarm.',
        alarm: data['alarm'] != null
            ? HydrationAlarmDto.fromJson(
                data['alarm'] as Map<String, dynamic>,
              )
            : null,
      );
    } catch (_) {
      return const HydrationAlarmResponse(
        success: false,
        message: 'Unable to connect to the server.',
      );
    }
  }

  Future<HydrationAlarmResponse> updateAlarm({
    required String id,
    required String label,
    required String scheduleType,
    required List<String> reminderTimes,
    required bool enabled,
    String? startTime,
    String? endTime,
    int? intervalMinutes,
    String tone = 'sound',
  }) async {
    try {
      final headers = await _authHeaders();

      if (headers == null) {
        return const HydrationAlarmResponse(
          success: false,
          message: 'Authentication token not found.',
        );
      }

      final response = await http.patch(
        Uri.parse('$baseUrl/$id'),
        headers: headers,
        body: jsonEncode({
          'label': label,
          'scheduleType': scheduleType,
          'reminderTimes': reminderTimes,
          'enabled': enabled,
          'startTime': startTime,
          'endTime': endTime,
          'intervalMinutes': intervalMinutes,
          'tone': tone,
        }),
      );

      final data = jsonDecode(response.body);

      return HydrationAlarmResponse(
        success: response.statusCode == 200,
        message: data['message'] ?? 'Failed to update hydration alarm.',
        alarm: data['alarm'] != null
            ? HydrationAlarmDto.fromJson(
                data['alarm'] as Map<String, dynamic>,
              )
            : null,
      );
    } catch (_) {
      return const HydrationAlarmResponse(
        success: false,
        message: 'Unable to connect to the server.',
      );
    }
  }

  Future<HydrationAlarmResponse> toggleAlarm(String id) async {
    try {
      final headers = await _authHeaders();

      if (headers == null) {
        return const HydrationAlarmResponse(
          success: false,
          message: 'Authentication token not found.',
        );
      }

      final response = await http.patch(
        Uri.parse('$baseUrl/$id/toggle'),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      return HydrationAlarmResponse(
        success: response.statusCode == 200,
        message: data['message'] ?? 'Failed to toggle hydration alarm.',
        alarm: data['alarm'] != null
            ? HydrationAlarmDto.fromJson(
                data['alarm'] as Map<String, dynamic>,
              )
            : null,
      );
    } catch (_) {
      return const HydrationAlarmResponse(
        success: false,
        message: 'Unable to connect to the server.',
      );
    }
  }

  Future<HydrationAlarmResponse> deleteAlarm(String id) async {
    try {
      final headers = await _authHeaders();

      if (headers == null) {
        return const HydrationAlarmResponse(
          success: false,
          message: 'Authentication token not found.',
        );
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/$id'),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      return HydrationAlarmResponse(
        success: response.statusCode == 200,
        message: data['message'] ?? 'Failed to delete hydration alarm.',
      );
    } catch (_) {
      return const HydrationAlarmResponse(
        success: false,
        message: 'Unable to connect to the server.',
      );
    }
  }
}