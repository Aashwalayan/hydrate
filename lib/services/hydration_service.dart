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

class HydrationService {
  static const String baseUrl =
      'https://hydrate-vor8.onrender.com/api/hydration';

  Future<HydrationResponse> saveSettings({
    required int dailyGoalMl,
    required bool enabled,
    required Duration interval,
    required String startTime,
    required String endTime,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null || token.isEmpty) {
        return const HydrationResponse(
          success: false,
          message: 'Authentication token not found.',
        );
      }

      final response = await http.post(
        Uri.parse('$baseUrl/settings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
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
}