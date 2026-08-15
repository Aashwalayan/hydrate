import 'package:flutter/material.dart';

/// Mock model for a single hydration reminder schedule.
///
/// Structured so a real notification-scheduling model can replace this
/// without touching the widgets that render it.
class HydrationAlarm {
  const HydrationAlarm({
    required this.label,
    required this.intervalMinutes,
    required this.startTime,
    required this.endTime,
    required this.enabled,
  });

  final String label;
  final int intervalMinutes;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final bool enabled;

  HydrationAlarm copyWith({bool? enabled}) {
    return HydrationAlarm(
      label: label,
      intervalMinutes: intervalMinutes,
      startTime: startTime,
      endTime: endTime,
      enabled: enabled ?? this.enabled,
    );
  }
}

/// Alarm management screen — controls WHEN Hydrate reminds the user, as
/// opposed to [HomeScreen] which is about today's progress.
class AlarmScreen extends StatefulWidget {
  const AlarmScreen({super.key});

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
  // --- Mock data. Replace with real state/providers later. -----------------
  HydrationAlarm _primaryAlarm = const HydrationAlarm(
    label: 'Hydration reminders',
    intervalMinutes: 60,
    startTime: TimeOfDay(hour: 8, minute: 0),
    endTime: TimeOfDay(hour: 22, minute: 0),
    enabled: true,
  );

  final List<HydrationAlarm> _additionalAlarms = const [
    HydrationAlarm(
      label: 'Workout hydration boost',
      intervalMinutes: 20,
      startTime: TimeOfDay(hour: 17, minute: 0),
      endTime: TimeOfDay(hour: 18, minute: 30),
      enabled: false,
    ),
    HydrationAlarm(
      label: 'Wind-down reminder',
      intervalMinutes: 90,
      startTime: TimeOfDay(hour: 20, minute: 0),
      endTime: TimeOfDay(hour: 22, minute: 30),
      enabled: true,
    ),
  ];

  void _togglePrimary(bool value) {
    setState(() => _primaryAlarm = _primaryAlarm.copyWith(enabled: value));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Text(
                    'Alarms',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'When Hydrate reminds you to drink',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _AlarmCard(
                    alarm: _primaryAlarm,
                    primary: true,
                    onToggle: _togglePrimary,
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Additional alarms',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (final alarm in _additionalAlarms)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _AlarmCard(
                        alarm: alarm,
                        primary: false,
                        // Toggling additional alarms will be wired to real
                        // state management later.
                        onToggle: (_) {},
                      ),
                    ),
                  const SizedBox(height: 8),
                  _AddAlarmButton(onTap: () {}),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlarmCard extends StatelessWidget {
  const _AlarmCard({
    required this.alarm,
    required this.primary,
    required this.onToggle,
  });

  final HydrationAlarm alarm;
  final bool primary;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: primary
            ? colorScheme.primaryContainer.withValues(alpha: 0.35)
            : colorScheme.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.onSurface.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  alarm.label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Switch(
                value: alarm.enabled,
                onChanged: onToggle,
                activeTrackColor: colorScheme.primary,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _AlarmDetail(
                  icon: Icons.repeat_rounded,
                  label: 'Every',
                  value: '${alarm.intervalMinutes} minutes',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _AlarmDetail(
                  icon: Icons.wb_sunny_outlined,
                  label: 'From',
                  value: alarm.startTime.format(context),
                ),
              ),
              Expanded(
                child: _AlarmDetail(
                  icon: Icons.nights_stay_outlined,
                  label: 'Until',
                  value: alarm.endTime.format(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AlarmDetail extends StatelessWidget {
  const _AlarmDetail({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Icon(icon, size: 18, color: colorScheme.onSurface.withValues(alpha: 0.5)),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AddAlarmButton extends StatelessWidget {
  const _AddAlarmButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: colorScheme.onSurface.withValues(alpha: 0.12),
              style: BorderStyle.solid,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_rounded,
                size: 20,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 8),
              Text(
                'Add alarm',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}