import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';
import 'theme/theme_provider.dart';
import 'screens/splash/splash_screen.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'theme/hydrate_theme.dart';

import 'services/notification_service.dart';
import 'services/alarm_service.dart';
import 'screens/alarm/alarm_ringing_screen.dart';

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
    await NotificationService.instance.initialize();

    NotificationService.instance.onResponse =
        AlarmService.instance.handleNotificationResponse;

    AlarmService.instance.onAlarmTriggered = _showAlarmRingingScreen;

    const nativeAlarmChannel = MethodChannel('com.hydrate/alarm');

    nativeAlarmChannel.setMethodCallHandler((call) async {
      if (call.method != 'alarmTriggered') return;

      final arguments = Map<String, dynamic>.from(call.arguments as Map);

      final alarmId = arguments['alarmId'] as int?;
      final label = arguments['label'] as String?;
      final scheduledTime = arguments['scheduledTime'] as int?;

      if (alarmId == null || label == null || scheduledTime == null) {
        return;
      }

      debugPrint(
        'HydrationAlarm: Flutter received native alarmTriggered for id=$alarmId',
      );

      final alarm = ActiveAlarm(
        id: alarmId,
        label: label,
        scheduledTime: DateTime.fromMillisecondsSinceEpoch(scheduledTime),
      );

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showAlarmRingingScreen(alarm);
      });
    });

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

    final nativeAlarm = await AlarmService.instance.getInitialNativeAlarm();

    if (nativeAlarm != null) {
      debugPrint(
        'HydrationAlarm: Flutter found initial native alarm id=${nativeAlarm.id}',
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showAlarmRingingScreen(nativeAlarm);
      });
    }
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
