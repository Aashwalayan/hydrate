import 'package:flutter/material.dart';

import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';
import 'theme/theme_provider.dart';
import 'screens/splash/splash_screen.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'theme/hydrate_theme.dart';

import 'services/notification_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HydrateApp());
}

class HydrateApp extends StatefulWidget {
  const HydrateApp({super.key});

  @override
  State<HydrateApp> createState() => _HydrateAppState();
}

class _HydrateAppState extends State<HydrateApp> {
  ThemeController? _themeController;

  @override
  void initState() {
    super.initState();
    _loadThemeSettings();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    print('NOTIFICATION: starting initialization');

    await NotificationService.instance.initialize();

    print('NOTIFICATION: initialization complete');

    await NotificationService.instance.testNotification();

    print('NOTIFICATION: test scheduled');
  }

  Future<void> _loadThemeSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final storedThemeMode = prefs.getString('theme_mode');
    final storedTheme = prefs.getString('hydrate_theme');

    final themeMode = ThemeMode.values.firstWhere(
      (mode) => mode.name == storedThemeMode,
      orElse: () => ThemeMode.system,
    );

    final hydrateTheme = HydrateTheme.values.firstWhere(
      (theme) => theme.name == storedTheme,
      orElse: () => HydrateTheme.calm,
    );

    if (!mounted) return;

    setState(() {
      _themeController = ThemeController(
        themeMode: themeMode,
        hydrateTheme: hydrateTheme,
      );
    });
  }

  @override
  void dispose() {
    _themeController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _themeController;

    if (controller == null) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        return ThemeControllerProvider(
          controller: controller,
          child: MaterialApp(
            title: 'Hydrate',
            debugShowCheckedModeBanner: false,
            navigatorKey: navigatorKey,
            themeMode: controller.themeMode,
            theme: AppTheme.lightTheme(controller.hydrateTheme),
            darkTheme: AppTheme.darkTheme(controller.hydrateTheme),
            home: const SplashScreen(),
          ),
        );
      },
    );
  }
}
