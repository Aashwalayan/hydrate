import 'package:flutter/material.dart';

import 'screens/auth/login_screen.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const HydrateApp());
}

class HydrateApp extends StatelessWidget {
  const HydrateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hydrate',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: LoginScreen(authService: AuthService()),
    );
  }
}
