import 'package:flutter/material.dart';

import 'screens/onboarding/welcome_screen.dart';
import 'screens/onboarding/goal_screen.dart';
import 'screens/onboarding/reminder_screen.dart';
import 'screens/onboarding/personalization_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const HydrateApp());
}

class HydrateApp extends StatelessWidget {
  const HydrateApp({super.key});

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hydrate',
      debugShowCheckedModeBanner: false,

      navigatorKey: navigatorKey,

      themeMode: ThemeMode.system,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,

      home: WelcomeScreen(
        onGetStarted: () {
          navigatorKey.currentState!.push(
            MaterialPageRoute(
              builder: (_) => GoalScreen(
                onContinue: (goal) {
                  navigatorKey.currentState!.push(
                    MaterialPageRoute(
                      builder: (_) => ReminderScreen(
                        onContinue: (
                          enabled,
                          interval,
                          startTime,
                          endTime,
                        ) {
                          navigatorKey.currentState!.push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  PersonalizationScreen(
                                onFinish: (
                                  themeMode,
                                  theme,
                                ) {
                                  // We'll connect this to Home later.
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}