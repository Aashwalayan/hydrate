import 'package:flutter/material.dart';
import 'personalization_screen.dart';
import '../../services/hydration_service.dart';

class ReminderScreen extends StatefulWidget {
  const ReminderScreen({
    super.key,
    this.initialEnabled = true,
    this.initialInterval = const Duration(hours: 1),
    this.initialStartTime,
    this.initialEndTime,
    this.onContinue,
    required this.dailyGoalMl,
  });

  final bool initialEnabled;
  final Duration initialInterval;
  final TimeOfDay? initialStartTime;
  final TimeOfDay? initialEndTime;
  final int dailyGoalMl;
  final void Function(
    bool enabled,
    Duration interval,
    TimeOfDay startTime,
    TimeOfDay endTime,
  )?
  onContinue;

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  late bool _remindersEnabled;
  late Duration _interval;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;

  final HydrationService _hydrationService = HydrationService();

  @override
  void initState() {
    super.initState();

    _remindersEnabled = widget.initialEnabled;
    _interval = widget.initialInterval;

    _startTime = widget.initialStartTime ?? const TimeOfDay(hour: 8, minute: 0);

    _endTime = widget.initialEndTime ?? const TimeOfDay(hour: 22, minute: 0);
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';

    return '$hour:$minute $period';
  }

  String _formatInterval(Duration interval) {
    if (interval.inMinutes < 60) {
      return '${interval.inMinutes} min';
    }

    final hours = interval.inMinutes ~/ 60;

    if (hours == 1) {
      return '1 hour';
    }

    return '$hours hours';
  }

  Future<void> _selectTime({required bool start}) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: start ? _startTime : _endTime,
      builder: (context, child) {
        final theme = Theme.of(context);

        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: theme.colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selected == null) return;

    setState(() {
      if (start) {
        _startTime = selected;
      } else {
        _endTime = selected;
      }
    });
  }

  String _formatTimeForApi(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  Future<void> _continue() async {
    final response = await _hydrationService.saveSettings(
      dailyGoalMl: widget.dailyGoalMl,
      enabled: _remindersEnabled,
      interval: _interval,
      startTime: _formatTimeForApi(_startTime),
      endTime: _formatTimeForApi(_endTime),
    );

    if (!mounted) return;

    if (!response.success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      return;
    }

    widget.onContinue?.call(_remindersEnabled, _interval, _startTime, _endTime);

    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const PersonalizationScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final primary = colorScheme.primary;
    final secondary = colorScheme.secondary;
    final surface = colorScheme.surface;

    return Scaffold(
      backgroundColor: surface,
      body: SafeArea(
        child: Stack(
          children: [
            _ReminderBackground(
              primary: primary,
              secondary: secondary,
            ),
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
              child: Column(
                children: [
                  _buildTopBar(context, primary),

                  const SizedBox(height: 18),

                  _buildProgressIndicator(context, primary),

                  const SizedBox(height: 28),

                  _buildHeader(context, primary),

                  const SizedBox(height: 28),

                  _buildEnableCard(context, primary),

                  const SizedBox(height: 20),

                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 250),
                    opacity: _remindersEnabled ? 1 : 0.45,
                    child: IgnorePointer(
                      ignoring: !_remindersEnabled,
                      child: Column(
                        children: [
                          _buildFrequencyCard(context, primary),

                          const SizedBox(height: 16),

                          _buildTimeCard(context, primary, secondary),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  _buildSchedulePreview(context, primary, secondary),

                  const SizedBox(height: 28),

                  _buildContinueButton(context, primary, secondary),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, Color primary) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        elevation: 2,
        shadowColor: primary.withValues(alpha: 0.18),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => Navigator.of(context).maybePop(),
          child: const SizedBox(
            width: 48,
            height: 48,
            child: Icon(Icons.arrow_back_rounded),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(BuildContext context, Color primary) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _progressCircle(context, '1', false, primary),
        _progressLine(context, primary, true),
        _progressCircle(context, '2', false, primary),
        _progressLine(context, primary, true),
        _progressCircle(context, '3', true, primary),
        _progressLine(context, primary, false),
        _progressCircle(context, '4', false, primary),
      ],
    );
  }

  Widget _progressCircle(
    BuildContext context,
    String number,
    bool active,
    Color primary,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? primary : colorScheme.surface,
        border: Border.all(
          color: active ? primary : colorScheme.outlineVariant,
          width: 2,
        ),
        boxShadow: active
            ? [
                BoxShadow(
                  color: primary.withValues(alpha: 0.25),
                  blurRadius: 10,
                ),
              ]
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        number,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: active ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _progressLine(BuildContext context, Color primary, bool active) {
    return Container(
      width: 32,
      height: 2,
      color: active
          ? primary.withValues(alpha: 0.55)
          : Theme.of(context).colorScheme.outlineVariant,
    );
  }

  Widget _buildHeader(BuildContext context, Color primary) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: primary.withValues(alpha: 0.12),
          ),
          child: Icon(
            Icons.notifications_none_rounded,
            size: 38,
            color: primary,
          ),
        ),

        const SizedBox(height: 20),

        Text(
          'Stay on track.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 30,
            height: 1.15,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: colorScheme.onSurface,
          ),
        ),

        const SizedBox(height: 10),

        Text(
          'We can gently remind you to drink\nwater throughout the day.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            height: 1.5,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildEnableCard(BuildContext context, Color primary) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _remindersEnabled
              ? primary.withValues(alpha: 0.35)
              : colorScheme.outlineVariant,
        ),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              _remindersEnabled
                  ? Icons.notifications_active_rounded
                  : Icons.notifications_off_rounded,
              color: primary,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hydration reminders',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _remindersEnabled
                      ? 'Gently remind me to drink'
                      : 'Reminders are turned off',
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          Switch.adaptive(
            value: _remindersEnabled,
            activeColor: primary,
            onChanged: (value) {
              setState(() {
                _remindersEnabled = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFrequencyCard(BuildContext context, Color primary) {
    final colorScheme = Theme.of(context).colorScheme;

    const intervals = [
      Duration(minutes: 30),
      Duration(hours: 1),
      Duration(hours: 1, minutes: 30),
      Duration(hours: 2),
    ];

    return _sectionCard(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Remind me every',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),

          const SizedBox(height: 14),

          Row(
            children: intervals.map((interval) {
              final selected = _interval == interval;

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: interval == intervals.last ? 0 : 8,
                  ),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _interval = interval;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: selected
                            ? primary.withValues(alpha: 0.11)
                            : colorScheme.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected
                              ? primary
                              : colorScheme.outlineVariant,
                          width: selected ? 1.5 : 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _formatInterval(interval),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: selected
                                ? primary
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeCard(BuildContext context, Color primary, Color secondary) {
    return _sectionCard(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Remind me between',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: _timeTile(
                  context,
                  label: 'Start',
                  time: _startTime,
                  primary: primary,
                  onTap: () => _selectTime(start: true),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),

              Expanded(
                child: _timeTile(
                  context,
                  label: 'End',
                  time: _endTime,
                  primary: secondary,
                  onTap: () => _selectTime(start: false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _timeTile(
    BuildContext context, {
    required String label,
    required TimeOfDay time,
    required Color primary,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.schedule_rounded, size: 17, color: primary),
                  const SizedBox(width: 6),
                  Text(
                    _formatTime(time),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSchedulePreview(
    BuildContext context,
    Color primary,
    Color secondary,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primary.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Icon(Icons.water_drop_rounded, color: primary, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _remindersEnabled
                      ? 'Your hydration plan'
                      : 'No reminders scheduled',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _remindersEnabled
                      ? 'Every ${_formatInterval(_interval)} '
                            'from ${_formatTime(_startTime)} '
                            'to ${_formatTime(_endTime)}'
                      : 'You can turn them on anytime in Settings.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard(BuildContext context, {required Widget child}) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.7),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildContinueButton(
    BuildContext context,
    Color primary,
    Color secondary,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: double.infinity,
      height: 58,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [primary, secondary]),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: primary.withValues(alpha: 0.25),
              blurRadius: 16,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _continue,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: colorScheme.onPrimary,
            shadowColor: Colors.transparent,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Continue',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              SizedBox(width: 10),
              Icon(Icons.arrow_forward_rounded, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReminderBackground extends StatelessWidget {
  const _ReminderBackground({required this.primary, required this.secondary});

  final Color primary;
  final Color secondary;

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;

    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                primary.withValues(alpha: 0.12),
                surface,
                secondary.withValues(alpha: 0.09),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
