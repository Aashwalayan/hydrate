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
  static const String baseUrl =
    'https://hydrate-api-622443979031.asia-south1.run.app/api/auth';

  Future<void> _saveUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
  }

  Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_name');
  }

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
    final value = prefs.getBool('onboarding_complete') ?? false;

    print('ONBOARDING COMPLETE: $value');

    return value;
  }

  Future<bool> hasValidSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    print('AUTH TOKEN ON STARTUP: $token');

    return token != null && token.isNotEmpty;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
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

        final user = data['user'];

        if (user != null) {
          if (user['name'] != null) {
            await _saveUserName(user['name']);
          }

          if (user['email'] != null) {
            await _saveUserEmail(user['email']);
          }
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

        final user = data['user'];

        if (user != null) {
          if (user['name'] != null) {
            await _saveUserName(user['name']);
          }

          if (user['email'] != null) {
            await _saveUserEmail(user['email']);
          }
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

  Future<AuthResponse> updateName(String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http.put(
        Uri.parse('$baseUrl/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'name': name}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        await _saveUserName(name);

        return AuthResponse(
          success: true,
          message: data['message'] ?? 'Name updated successfully.',
        );
      }

      return AuthResponse(
        success: false,
        message: data['message'] ?? 'Failed to update name.',
      );
    } catch (e) {
      return const AuthResponse(
        success: false,
        message: 'Unable to connect to the server.',
      );
    }
  }

  Future<AuthResponse> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http.post(
        Uri.parse('$baseUrl/change-password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );

      final data = jsonDecode(response.body);

      return AuthResponse(
        success: response.statusCode == 200,
        message: data['message'] ?? 'Failed to change password.',
      );
    } catch (e) {
      return const AuthResponse(
        success: false,
        message: 'Unable to connect to the server.',
      );
    }
  }

  Future<AuthResponse> deleteAccount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http.delete(
        Uri.parse('$baseUrl/me'),
        headers: {'Authorization': 'Bearer $token'},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        await prefs.remove('auth_token');
        await prefs.remove('user_name');

        return AuthResponse(
          success: true,
          message: data['message'] ?? 'Account deleted successfully.',
        );
      }

      return AuthResponse(
        success: false,
        message: data['message'] ?? 'Failed to delete account.',
      );
    } catch (e) {
      return const AuthResponse(
        success: false,
        message: 'Unable to connect to the server.',
      );
    }
  }

  Future<void> _saveUserEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_email', email);
  }

  Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_email');
  }
}
