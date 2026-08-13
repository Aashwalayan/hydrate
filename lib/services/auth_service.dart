import 'dart:convert';
import 'package:http/http.dart' as http;

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
  static const String baseUrl = 'http://10.0.2.2:4000/api/auth';

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return AuthResponse(
          success: true,
          message: data['message'] ?? 'Login successful.',
          token: data['token'],
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
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      return AuthResponse(
        success: response.statusCode == 201,
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
        body: jsonEncode({
          'email': email,
          'otp': otp,
        }),
      );

      final data = jsonDecode(response.body);

      return AuthResponse(
        success: response.statusCode == 200,
        message: data['message'] ?? 'Verification failed.',
      );
    } catch (e) {
      return const AuthResponse(
        success: false,
        message: 'Unable to connect to the server.',
      );
    }
  }
}