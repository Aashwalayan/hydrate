import 'package:flutter/material.dart';

import '../home/main_screen.dart';
import 'signup_screen.dart';
import '../onboarding/welcome_screen.dart';
import '../../services/auth_service.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final AuthService _authService = AuthService();

  late Future<Widget> _initialScreen;

  @override
  void initState() {
    super.initState();
    _initialScreen = _getInitialScreen();
  }

  Future<Widget> _getInitialScreen() async {
    final hasSession = await _authService.hasValidSession();


    if (!hasSession) {
      return WelcomeScreen(
        onGetStarted: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => SignupScreen(authService: _authService),
            ),
          );
        },
      );
    }

    final onboardingComplete = await _authService.isOnboardingComplete();

    if (onboardingComplete) {
      return const MainScreen();
    }

    // If authenticated but onboarding wasn't completed,
    // we'll resume onboarding here.
    return WelcomeScreen(
      onGetStarted: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => SignupScreen(authService: _authService),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _initialScreen,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text('Something went wrong.')),
          );
        }

        return snapshot.data!;
      },
    );
  }
}
