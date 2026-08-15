import 'package:flutter/material.dart';

import 'screens/auth/signup_screen.dart';
import 'screens/onboarding/welcome_screen.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';
import 'theme/theme_provider.dart';

final GlobalKey<NavigatorState> navigatorKey =
    GlobalKey<NavigatorState>();

void main() {
  runApp(const HydrateApp());
}

class HydrateApp extends StatefulWidget {
  const HydrateApp({super.key});

  @override
  State<HydrateApp> createState() => _HydrateAppState();
}

class _HydrateAppState extends State<HydrateApp> {
  final ThemeController _themeController =
      ThemeController();

  @override
  void dispose() {
    _themeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
  listenable: _themeController,
  builder: (context, child) {
    return ThemeControllerProvider(
      controller: _themeController,
      child: MaterialApp(
          title: 'Hydrate',
          debugShowCheckedModeBanner: false,

          navigatorKey: navigatorKey,

          themeMode: _themeController.themeMode,

          theme: AppTheme.lightTheme(
            _themeController.hydrateTheme,
          ),

          darkTheme: AppTheme.darkTheme(
            _themeController.hydrateTheme,
          ),

          home: WelcomeScreen(
            onGetStarted: () {
              navigatorKey.currentState!.push(
                MaterialPageRoute(
                  builder: (_) => SignupScreen(
                    authService: AuthService(),
                  ),
                ),
              );
            },
          ),
      )
        );
      },
    );
  }
}