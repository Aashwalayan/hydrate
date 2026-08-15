import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthResponse {
  const AuthResponse({
    required this.success,
    required this.message,
    this.token,
  });

  final bool success;
  final String message;
  final String? token;
}

class AuthService {
  // Android emulator → your computer's localhost
  static const String baseUrl = 'https://hydrate-vor8.onrender.com/api/auth';

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<void> setOnboardingComplete(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', value);
  }

  Future<bool> isOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('onboarding_complete') ?? false;
  }

  Future<bool> hasValidSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    return token != null && token.isNotEmpty;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('onboarding_complete');
  }

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final token = data['token'];

        if (token != null) {
          await _saveToken(token);
        }

        return AuthResponse(
          success: true,
          message: data['message'] ?? 'Login successful.',
          token: token,
        );
      }

      return AuthResponse(
        success: false,
        message: data['message'] ?? 'Login failed.',
      );
    } catch (e) {
      return const AuthResponse(
        success: false,
        message: 'Unable to connect to the server.',
      );
    }
  }

  Future<AuthResponse> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'email': email, 'password': password}),
      );

      final data = jsonDecode(response.body);

      return AuthResponse(
        // Accept both 200 and 201 just in case
        success: response.statusCode == 200 || response.statusCode == 201,
        message: data['message'] ?? 'Signup failed.',
      );
    } catch (e) {
      print('ERROR CONNECTING: $e');
      return const AuthResponse(
        success: false,
        message: 'Unable to connect to the server.',
      );
    }
  }

  Future<AuthResponse> verifyEmail({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/verify-email'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'otp': otp}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final token = data['token'];

        if (token != null) {
          await _saveToken(token);
        }

        return AuthResponse(
          success: true,
          message: data['message'] ?? 'Email verified successfully.',
          token: token,
        );
      }

      return AuthResponse(
        success: false,
        message: data['message'] ?? 'Verification failed.',
      );
    } catch (e) {
      return const AuthResponse(
        success: false,
        message: 'Unable to connect to the server.',
      );
    }
  }

  Future<AuthResponse> resendVerificationCode({required String email}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/resend-verification'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      final data = jsonDecode(response.body);

      return AuthResponse(
        success: response.statusCode == 200,
        message: data['message'] ?? 'Failed to resend verification code.',
      );
    } catch (e) {
      return const AuthResponse(
        success: false,
        message: 'Unable to connect to the server.',
      );
    }
  }

  Future<AuthResponse> forgotPassword({required String email}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      final data = jsonDecode(response.body);

      return AuthResponse(
        success: response.statusCode == 200,
        message: data['message'] ?? 'Failed to send reset code.',
      );
    } catch (e) {
      return const AuthResponse(
        success: false,
        message: 'Unable to connect to the server.',
      );
    }
  }

  Future<AuthResponse> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'code': code,
          'newPassword': newPassword,
        }),
      );

      final data = jsonDecode(response.body);

      return AuthResponse(
        success: response.statusCode == 200,
        message: data['message'] ?? 'Failed to reset password.',
      );
    } catch (e) {
      return const AuthResponse(
        success: false,
        message: 'Unable to connect to the server.',
      );
    }
  }
}
