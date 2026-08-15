import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/auth_service.dart';
import '../../widgets/auth_scaffold.dart';
import '../../widgets/auth_text_field.dart';
import '../../widgets/primary_button.dart';
import 'login_screen.dart';
import '../onboarding/goal_screen.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({
    super.key,
    required this.authService,
    required this.email,
    this.onVerified,
  });

  final AuthService authService;
  final String email;
  final VoidCallback? onVerified;

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  static const int _resendDelaySeconds = 30;

  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();

  Timer? _timer;
  int _remainingSeconds = _resendDelaySeconds;
  bool _isSubmitting = false;
  bool _isResending = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();

    setState(() {
      _remainingSeconds = _resendDelaySeconds;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 1) {
        timer.cancel();

        if (mounted) {
          setState(() {
            _remainingSeconds = 0;
          });
        }
      } else if (mounted) {
        setState(() {
          _remainingSeconds--;
        });
      }
    });
  }

  Future<void> _verify() async {
    final form = _formKey.currentState;

    if (form == null || !form.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isSubmitting = true;
    });

    final response = await widget.authService.verifyEmail(
      email: widget.email,
      otp: _otpController.text.trim(),
    );

    if (!mounted) {
      return;
    }

    if (response.success && response.token != null) {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('auth_token', response.token!);

      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const GoalScreen()),
      );
    }

    setState(() {
      _isSubmitting = false;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(response.message)));

    if (response.success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const GoalScreen()),
      );
    }
  }

  Future<void> _resendCode() async {
    if (_remainingSeconds > 0) {
      return;
    }

    setState(() {
      _isResending = true;
    });

    final response = await widget.authService.resendVerificationCode(
      email: widget.email,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isResending = false;
    });

    _startTimer();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(response.message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: AuthScaffold(
        title: 'Verify your email',
        subtitle: 'Enter the 6-digit code sent to ${widget.email}.',
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.mark_email_read_outlined,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.email,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              AuthTextField(
                controller: _otpController,
                label: 'Verification code',
                hintText: '123456',
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                prefixIcon: Icons.password_rounded,
                maxLength: 6,
                autofillHints: const [AutofillHints.oneTimeCode],
                validator: (value) {
                  final trimmedValue = value?.trim() ?? '';

                  if (trimmedValue.isEmpty) {
                    return 'Verification code is required.';
                  }

                  if (!RegExp(r'^\d{6}$').hasMatch(trimmedValue)) {
                    return 'Enter a valid 6-digit code.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 24),

              PrimaryButton(
                label: 'Verify',
                isLoading: _isSubmitting,
                onPressed: _verify,
              ),

              const SizedBox(height: 18),

              TextButton(
                onPressed: _isResending || _remainingSeconds > 0
                    ? null
                    : _resendCode,
                child: _isResending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2.2),
                      )
                    : Text(
                        _remainingSeconds > 0
                            ? 'Resend code in '
                                  '${_remainingSeconds}s'
                            : 'Resend OTP',
                      ),
              ),

              const SizedBox(height: 8),

              TextButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          LoginScreen(authService: widget.authService),
                    ),
                    (route) => false,
                  );
                },
                child: const Text('Back to login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
