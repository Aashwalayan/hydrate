import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

const MethodChannel _alarmLaunchChannel = MethodChannel(
  'com.hydrate/alarm_launch',
);

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
  }

  Future<void> _handleInitialAlarmLaunch() async {
    final result = await _alarmLaunchChannel.invokeMethod<dynamic>(
      'getInitialAlarm',
    );

    if (result == null) return;

    final data = Map<String, dynamic>.from(result as Map);

    final alarmId = data['alarmId'] as int?;
    final label = data['alarmBody'] as String?;

    if (alarmId == null || label == null) return;

    final alarm = ActiveAlarm(
      id: alarmId,
      label: label,
      scheduledTime: DateTime.now(),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showAlarmRingingScreen(alarm);
    });
  }

  Future<void> _testAlarmService() async {
    final time = DateTime.now().add(const Duration(minutes: 1));

    await AlarmService.instance.scheduleAlarm(
      id: 'migration_test',
      label: 'AlarmService migration test',
      reminderTimes: [time],
    );
    final alarms = await Alarm.getAlarms();

    for (final alarm in alarms) {
      debugPrint('SCHEDULED ALARM: id=${alarm.id}, dateTime=${alarm.dateTime}');
    }

    debugPrint('ALARM SERVICE TEST SCHEDULED: $time');
  }

  Future<void> _initializeNotifications() async {
    await NotificationService.instance.initialize();
    AlarmService.instance.onAlarmTriggered = _showAlarmRingingScreen;
    AlarmService.instance.initialize();
    await _handleInitialAlarmLaunch();
    await _testAlarmService();
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
