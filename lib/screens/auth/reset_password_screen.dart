import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../widgets/auth_scaffold.dart';
import '../../widgets/auth_text_field.dart';
import '../../widgets/primary_button.dart';
import 'login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({
    super.key,
    required this.authService,
    required this.email,
  });

  final AuthService authService;
  final String email;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);

    final response = await widget.authService.resetPassword(
      email: widget.email,
      code: _codeController.text.trim(),
      newPassword: _passwordController.text,
    );

    if (!mounted) {
      return;
    }

    setState(() => _isSubmitting = false);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(response.message)));

    if (response.success) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => LoginScreen(authService: widget.authService),
        ),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: AuthScaffold(
        title: 'Reset your password',
        subtitle:
            'Use the code sent to ${widget.email} and choose a new password.',
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  widget.email,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              AuthTextField(
                controller: _codeController,
                label: 'Reset code',
                hintText: '123456',
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                prefixIcon: Icons.numbers_rounded,
                validator: (value) {
                  final trimmedValue = value?.trim() ?? '';
                  if (trimmedValue.isEmpty) {
                    return 'Reset code is required.';
                  }
                  if (trimmedValue.length < 4) {
                    return 'Enter a valid reset code.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AuthTextField(
                controller: _passwordController,
                label: 'New password',
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.next,
                prefixIcon: Icons.lock_outline_rounded,
                autofillHints: const [AutofillHints.newPassword],
                validator: _validatePassword,
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              AuthTextField(
                controller: _confirmPasswordController,
                label: 'Confirm password',
                obscureText: _obscureConfirmPassword,
                textInputAction: TextInputAction.done,
                prefixIcon: Icons.verified_user_outlined,
                autofillHints: const [AutofillHints.newPassword],
                validator: (value) {
                  if ((value ?? '').isEmpty) {
                    return 'Please confirm your password.';
                  }
                  if (value != _passwordController.text) {
                    return 'Passwords do not match.';
                  }
                  return null;
                },
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword,
                    );
                  },
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Reset password',
                isLoading: _isSubmitting,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) {
      return 'Password is required.';
    }
    if (password.length < 8) {
      return 'Use at least 8 characters.';
    }
    final hasLetter = RegExp(r'[A-Za-z]').hasMatch(password);
    final hasNumber = RegExp(r'[0-9]').hasMatch(password);
    if (!hasLetter || !hasNumber) {
      return 'Include both letters and numbers.';
    }
    return null;
  }
}
