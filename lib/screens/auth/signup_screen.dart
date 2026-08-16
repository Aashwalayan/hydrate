import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../widgets/auth_scaffold.dart';
import '../../widgets/auth_text_field.dart';
import '../../widgets/primary_button.dart';
import 'login_screen.dart';
import 'verify_email_screen.dart';
import '../onboarding/goal_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key, required this.authService});

  final AuthService authService;

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
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

    final response = await widget.authService.signup(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) {
      return;
    }

    setState(() => _isSubmitting = false);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(response.message)));

    if (response.success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => VerifyEmailScreen(
            authService: widget.authService,
            email: _emailController.text.trim(),
            onVerified: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute<void>(builder: (_) => const GoalScreen()),
              );
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: AuthScaffold(
        title: 'Create your account',
        subtitle: 'Set up your wellness companion in a few quick steps.',
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthTextField(
                controller: _nameController,
                label: 'Name',
                hintText: 'nomnomgng',
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                prefixIcon: Icons.person_outline_rounded,
                autofillHints: const [AutofillHints.name],
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) {
                    return 'Name is required.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AuthTextField(
                controller: _emailController,
                label: 'Email',
                hintText: 'you@example.com',
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                prefixIcon: Icons.mail_outline_rounded,
                autofillHints: const [AutofillHints.email],
                validator: _validateEmail,
              ),
              const SizedBox(height: 16),
              AuthTextField(
                controller: _passwordController,
                label: 'Password',
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
                label: 'Create account',
                isLoading: _isSubmitting,
                onPressed: _submit,
              ),
              const SizedBox(height: 18),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 2,
                children: [
                  Text(
                    'Already have an account?',
                    style: theme.textTheme.bodyMedium,
                  ),
                  TextButton(
                    onPressed: _isSubmitting
                        ? null
                        : () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute<void>(
                                builder: (_) => LoginScreen(
                                  authService: widget.authService,
                                ),
                              ),
                            );
                          },
                    child: const Text('Login'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _validateEmail(String? value) {
    final trimmedValue = value?.trim() ?? '';
    if (trimmedValue.isEmpty) {
      return 'Email is required.';
    }
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(trimmedValue)) {
      return 'Enter a valid email address.';
    }
    return null;
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
