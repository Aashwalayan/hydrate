import 'package:flutter/material.dart';

import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';
import 'theme/theme_provider.dart';
import 'screens/splash/splash_screen.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:alarm/alarm.dart';

import 'theme/hydrate_theme.dart';

import 'services/notification_service.dart';
import 'services/alarm_service.dart';
import 'screens/alarm/alarm_ringing_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Alarm.init();

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
    _listenForAlarmPackage();
  }

  void _listenForAlarmPackage() {
    Alarm.ringing.listen((alarmSet) {
      for (final alarm in alarmSet.alarms) {
        debugPrint(
          'ALARM PACKAGE FIRED: id=${alarm.id}, '
          'payload=${alarm.payload}',
        );
      }
    });
  }

  Future<void> _testAlarm() async {
    final settings = AlarmSettings(
      id: 999999,
      dateTime: DateTime.now().add(const Duration(minutes: 1)),
      assetAudioPath: 'assets/sounds/alarm.mp3',
      loopAudio: true,
      vibrate: true,
      androidFullScreenIntent: true,
      warningNotificationOnKill: false,
      volumeSettings: const VolumeSettings.fixed(volume: 1.0),
      notificationSettings: const NotificationSettings(
        title: 'Hydrate Test',
        body: 'This is a test alarm',
        stopButton: 'Dismiss',
      ),
    );

    await Alarm.set(alarmSettings: settings);

    debugPrint('TEST ALARM SCHEDULED');
  }

  Future<void> _initializeNotifications() async {
    await NotificationService.instance.initialize();


    

    NotificationService.instance.onResponse =
        AlarmService.instance.handleNotificationResponse;

    AlarmService.instance.onAlarmTriggered = _showAlarmRingingScreen;

    final launchDetails = await NotificationService.instance.getLaunchDetails();

    if (launchDetails?.didNotificationLaunchApp == true) {
      final alarm = ActiveAlarm.decode(
        launchDetails!.notificationResponse?.payload,
      );

      if (alarm != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showAlarmRingingScreen(alarm);
        });
      }
    }
    await _testAlarm();
  }

  void _showAlarmRingingScreen(ActiveAlarm alarm) {
    final navigator = navigatorKey.currentState;

    if (navigator == null) return;

    navigator.push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => AlarmRingingScreen(
          alarmId: alarm.id,
          label: alarm.label,
          scheduledTime: alarm.scheduledTime,
        ),
      ),
    );
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
