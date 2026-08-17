import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/alarm_service.dart';

/// Shown when a hydration alarm fires. Reachable three ways, all converging
/// on the same widget:
///
/// 1. Foreground: NotificationService -> AlarmService -> navigatorKey push.
/// 2. Backgrounded (isolate alive): same path as above.
/// 3. Terminated: Android launches MainActivity fresh via the full-screen
///    intent; `main.dart` checks `NotificationService.getLaunchDetails()`
///    once at startup and pushes this screen after the first frame.
///
/// This widget intentionally knows nothing about scheduling, cancellation,
/// or notification IDs beyond the single [alarmId] it was given — all of
/// that lives in [AlarmService]. It only displays the alarm and reports the
/// user's choice (dismiss/snooze) back to the service.
class AlarmRingingScreen extends StatefulWidget {
  const AlarmRingingScreen({
    super.key,
    required this.alarmId,
    required this.label,
    required this.scheduledTime,
    this.userName,
  });

  final int alarmId;
  final String label;
  final DateTime scheduledTime;

  /// Optional — if omitted, the screen shows a generic "Stay hydrated"
  /// tagline instead of a personalized one. Deliberately not required so
  /// this screen never needs the full user/auth context to render.
  final String? userName;

  @override
  State<AlarmRingingScreen> createState() => _AlarmRingingScreenState();
}

class _AlarmRingingScreenState extends State<AlarmRingingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bobController;
  Timer? _hapticTimer;
  bool _isResolving = false;

  @override
  void initState() {
    super.initState();

    _bobController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // Sustained vibration while the alarm is active. This uses only
    // Flutter's built-in HapticFeedback rather than adding a vibration
    // package — see the accompanying explanation for the real limitation
    // this leaves (haptics are lighter than a true alarm vibration pattern,
    // and continuous looped *sound* isn't covered by this at all).
    _hapticTimer = Timer.periodic(const Duration(milliseconds: 800), (_) {
      HapticFeedback.vibrate();
    });
  }

  @override
  void dispose() {
    _hapticTimer?.cancel();
    _bobController.dispose();
    super.dispose();
  }

  void _stopAlarmFeedback() {
    _hapticTimer?.cancel();
    _hapticTimer = null;
  }

  Future<void> _handleDismiss() async {
    if (_isResolving) return;
    setState(() => _isResolving = true);

    _stopAlarmFeedback();
    await AlarmService.instance.dismiss(widget.alarmId);

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _handleSnooze() async {
    if (_isResolving) return;
    setState(() => _isResolving = true);

    _stopAlarmFeedback();
    final alarm = ActiveAlarm(
      id: widget.alarmId,
      label: widget.label,
      scheduledTime: widget.scheduledTime,
    );
    await AlarmService.instance.snooze(alarm);

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return PopScope(
      // The system back gesture shouldn't silently leave the alarm ringing
      // in the background — dismiss is the deliberate way out.
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _handleDismiss();
      },
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              children: [
                const Spacer(flex: 2),
                Text(
                  TimeOfDay.now().format(context),
                  style: theme.textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Time to hydrate',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface.withValues(alpha: 0.75),
                  ),
                ),
                const Spacer(flex: 2),
                AnimatedBuilder(
                  animation: _bobController,
                  builder: (context, child) {
                    final offset = Curves.easeInOut.transform(_bobController.value);
                    return Transform.translate(
                      offset: Offset(0, -6 * offset),
                      child: child,
                    );
                  },
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colorScheme.primary,
                          colorScheme.primary.withValues(alpha: 0.75),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.35),
                          blurRadius: 32,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.water_drop_rounded,
                      color: colorScheme.onPrimary,
                      size: 56,
                    ),
                  ),
                ),
                const Spacer(flex: 2),
                Text(
                  widget.userName != null
                      ? 'Stay hydrated, ${widget.userName}'
                      : 'Stay hydrated',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    widget.label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface.withValues(alpha: 0.75),
                    ),
                  ),
                ),
                const Spacer(flex: 3),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _isResolving ? null : _handleSnooze,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      side: BorderSide(
                        color: colorScheme.onSurface.withValues(alpha: 0.15),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Text(
                      'Snooze · ${AlarmService.defaultSnoozeDuration.inMinutes} min',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isResolving ? null : _handleDismiss,
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Text(
                      'Dismiss',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}