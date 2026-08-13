import 'dart:async';

class AuthResponse {
  const AuthResponse({required this.success, required this.message});

  final bool success;
  final String message;
}

class AuthService {
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));

    // TODO: Replace with POST /auth/login when backend is ready.
    return const AuthResponse(success: true, message: 'Login successful.');
  }

  Future<AuthResponse> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 1100));

    // TODO: Replace with POST /auth/signup when backend is ready.
    return const AuthResponse(
      success: true,
      message: 'Account created. Verify your email to continue.',
    );
  }

  Future<AuthResponse> verifyEmail({
    required String email,
    required String otp,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));

    // TODO: Replace with POST /auth/verify-email when backend is ready.
    return const AuthResponse(success: true, message: 'Email verified.');
  }

  Future<AuthResponse> resendVerificationCode({required String email}) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));

    // TODO: Replace with POST /auth/resend-verification-code later.
    return const AuthResponse(
      success: true,
      message: 'A new verification code has been sent.',
    );
  }

  Future<AuthResponse> forgotPassword({required String email}) async {
    await Future<void>.delayed(const Duration(milliseconds: 850));

    // TODO: Replace with POST /auth/forgot-password when backend is ready.
    return const AuthResponse(success: true, message: 'Reset code sent.');
  }

  Future<AuthResponse> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 950));

    // TODO: Replace with POST /auth/reset-password when backend is ready.
    return const AuthResponse(
      success: true,
      message: 'Password reset successful.',
    );
  }
}
