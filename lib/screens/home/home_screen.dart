import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Mock model for a single logged hydration entry.
///
/// Structured so a real backend/hydration-record model can replace this
/// 1:1 later without touching the widgets that consume it.
class HydrationEntry {
  const HydrationEntry({required this.amountMl, required this.time});

  final int amountMl;
  final TimeOfDay time;
}

/// Primary dashboard: today's hydration progress, quick add, next reminder,
/// and today's intake history.
///
/// This screen renders independently — it does NOT own a `PageView`. A
/// parent navigation container is expected to host `HomeScreen`,
/// `AlarmScreen`, and `ProfileScreen` as pages, with `HydrateBottomNavBar`
/// stacked on top so nav and content always appear together.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // --- Mock data. Replace with real state/providers later. -----------------
  final String userName = 'Aashwalayan';
  final double currentIntake = 1250;
  final double dailyGoal = 2500;

  final List<HydrationEntry> todaysIntake = const [
    HydrationEntry(amountMl: 250, time: TimeOfDay(hour: 14, minute: 30)),
    HydrationEntry(amountMl: 300, time: TimeOfDay(hour: 13, minute: 15)),
    HydrationEntry(amountMl: 250, time: TimeOfDay(hour: 11, minute: 45)),
    HydrationEntry(amountMl: 450, time: TimeOfDay(hour: 9, minute: 30)),
  ];

  static const Duration _mockReminderInterval = Duration(
    minutes: 42,
    seconds: 18,
  );
  int _reminderSecondsRemaining = _mockReminderInterval.inSeconds;
  Timer? _countdownTimer;
  bool _justSkipped = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_reminderSecondsRemaining <= 0) {
          // Mock reset — a real implementation would pull the next
          // scheduled reminder from the alarm/notification system.
          _reminderSecondsRemaining = _mockReminderInterval.inSeconds;
        } else {
          _reminderSecondsRemaining -= 1;
        }
      });
    });
  }

  void _handleSkip() {
    setState(() {
      _justSkipped = true;
      _reminderSecondsRemaining = _mockReminderInterval.inSeconds;
    });
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _justSkipped = false);
    });
  }

  Future<void> _openAddWaterSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _AddWaterSheet(),
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
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
                  _Greeting(userName: userName),
                  const SizedBox(height: 28),
                  _HydrationProgress(
                    currentIntake: currentIntake,
                    dailyGoal: dailyGoal,
                  ),
                  const SizedBox(height: 24),
                  _AddWaterButton(onTap: _openAddWaterSheet),
                  const SizedBox(height: 24),
                  _NextReminderCard(
                    secondsRemaining: _reminderSecondsRemaining,
                    totalSeconds: _mockReminderInterval.inSeconds,
                    justSkipped: _justSkipped,
                    onSkip: _handleSkip,
                  ),
                  const SizedBox(height: 28),
                  _IntakeHistory(entries: todaysIntake),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Greeting
// ---------------------------------------------------------------------------

class _Greeting extends StatelessWidget {
  const _Greeting({required this.userName});

  final String userName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Good morning, $userName',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Let's stay hydrated today",
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Hydration progress — animated water-fill circle
// ---------------------------------------------------------------------------

class _HydrationProgress extends StatefulWidget {
  const _HydrationProgress({
    required this.currentIntake,
    required this.dailyGoal,
  });

  final double currentIntake;
  final double dailyGoal;

  @override
  State<_HydrationProgress> createState() => _HydrationProgressState();
}

class _HydrationProgressState extends State<_HydrationProgress>
    with TickerProviderStateMixin {
  late final AnimationController _loadController;
  late final Animation<double> _fillAnimation;
  late final AnimationController _waveController;

  double get _progress =>
      (widget.currentIntake / widget.dailyGoal).clamp(0.0, 1.0);

  @override
  void initState() {
    super.initState();
    _loadController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _fillAnimation = Tween<double>(begin: 0, end: _progress).animate(
      CurvedAnimation(parent: _loadController, curve: Curves.easeOutCubic),
    );
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _loadController.forward();
  }

  @override
  void dispose() {
    _loadController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        children: [
          Text(
            'TODAY',
            style: theme.textTheme.labelMedium?.copyWith(
              letterSpacing: 2,
              color: colorScheme.onSurface.withValues(alpha: 0.5),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 220,
            height: 220,
            child: AnimatedBuilder(
              animation: Listenable.merge([_fillAnimation, _waveController]),
              builder: (context, child) {
                return CustomPaint(
                  painter: _WaterCirclePainter(
                    fillLevel: _fillAnimation.value,
                    wavePhase: _waveController.value * 2 * math.pi,
                    fillColor: colorScheme.primary,
                    trackColor: colorScheme.onSurface.withValues(alpha: 0.06),
                    borderColor: colorScheme.onSurface.withValues(alpha: 0.08),
                  ),
                  child: child,
                );
              },
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.water_drop_rounded,
                      color: colorScheme.primary,
                      size: 28,
                    ),
                    const SizedBox(height: 6),
                    AnimatedBuilder(
                      animation: _fillAnimation,
                      builder: (context, _) {
                        final shownMl =
                            (widget.dailyGoal * _fillAnimation.value).round();
                        return Text(
                          '$shownMl ml',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        );
                      },
                    ),
                    Text(
                      '/ ${widget.dailyGoal.round()} ml',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                    const SizedBox(height: 8),
                    AnimatedBuilder(
                      animation: _fillAnimation,
                      builder: (context, _) {
                        return Text(
                          '${(_fillAnimation.value * 100).round()}%',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Paints a circular track with an animated liquid fill and a gentle wave
/// along the water's surface, clipped to the circle.
class _WaterCirclePainter extends CustomPainter {
  _WaterCirclePainter({
    required this.fillLevel,
    required this.wavePhase,
    required this.fillColor,
    required this.trackColor,
    required this.borderColor,
  });

  final double fillLevel;
  final double wavePhase;
  final Color fillColor;
  final Color trackColor;
  final Color borderColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Background track.
    final trackPaint = Paint()..color = trackColor;
    canvas.drawCircle(center, radius, trackPaint);

    // Clip to circle, then paint the wavy liquid fill inside it.
    canvas.save();
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: center, radius: radius)),
    );

    final waterHeight = size.height * (1 - fillLevel);
    const waveAmplitude = 6.0;
    const waveLength = 90.0;

    final path = Path()..moveTo(0, size.height);
    path.lineTo(0, waterHeight);
    for (double x = 0; x <= size.width; x++) {
      final y = waterHeight +
          waveAmplitude *
              math.sin((x / waveLength * 2 * math.pi) + wavePhase);
      path.lineTo(x, y);
    }
    path.lineTo(size.width, size.height);
    path.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          fillColor.withValues(alpha: 0.65),
          fillColor.withValues(alpha: 0.85),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(path, fillPaint);
    canvas.restore();

    // Border ring on top.
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = borderColor;
    canvas.drawCircle(center, radius - 1, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _WaterCirclePainter oldDelegate) {
    return oldDelegate.fillLevel != fillLevel ||
        oldDelegate.wavePhase != wavePhase ||
        oldDelegate.fillColor != fillColor;
  }
}

// ---------------------------------------------------------------------------
// Add Water button
// ---------------------------------------------------------------------------

class _AddWaterButton extends StatelessWidget {
  const _AddWaterButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.primary,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: colorScheme.onPrimary.withValues(alpha: 0.18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_rounded, color: colorScheme.onPrimary),
              const SizedBox(width: 8),
              Text(
                'Add Water',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddWaterSheet extends StatefulWidget {
  const _AddWaterSheet();

  @override
  State<_AddWaterSheet> createState() => _AddWaterSheetState();
}

class _AddWaterSheetState extends State<_AddWaterSheet> {
  static const List<int> _quickAmounts = [150, 250, 350, 500];
  int? _selectedAmount = 250;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(
            top: BorderSide(
              color: colorScheme.onSurface.withValues(alpha: 0.08),
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            Text(
              'How much did you drink?',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final amount in _quickAmounts)
                  _AmountChip(
                    label: '$amount ml',
                    selected: _selectedAmount == amount,
                    onTap: () => setState(() => _selectedAmount = amount),
                  ),
                _AmountChip(
                  label: 'Custom',
                  selected: _selectedAmount == null,
                  onTap: () => setState(() => _selectedAmount = null),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                // Wiring this up to real hydration-record state is left for
                // later — currently just closes the sheet.
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Add'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AmountChip extends StatelessWidget {
  const _AmountChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: selected
          ? colorScheme.primary.withValues(alpha: 0.14)
          : colorScheme.onSurface.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? colorScheme.primary
                  : colorScheme.onSurface.withValues(alpha: 0.1),
            ),
          ),
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: selected ? colorScheme.primary : colorScheme.onSurface,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Next reminder + skip
// ---------------------------------------------------------------------------

class _NextReminderCard extends StatelessWidget {
  const _NextReminderCard({
    required this.secondsRemaining,
    required this.totalSeconds,
    required this.justSkipped,
    required this.onSkip,
  });

  final int secondsRemaining;
  final int totalSeconds;
  final bool justSkipped;
  final VoidCallback onSkip;

  String get _formatted {
    final minutes = secondsRemaining ~/ 60;
    final seconds = secondsRemaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.onSurface.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'NEXT REMINDER',
                style: theme.textTheme.labelMedium?.copyWith(
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
              AnimatedOpacity(
                opacity: justSkipped ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child: Text(
                  'Skipped',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Text(
              _formatted,
              key: ValueKey(_formatted),
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.water_drop_outlined,
                    size: 18,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Drink 250 ml',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: onSkip,
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.onSurface.withValues(
                    alpha: 0.6,
                  ),
                ),
                child: const Text('Skip'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Today's intake history
// ---------------------------------------------------------------------------

class _IntakeHistory extends StatelessWidget {
  const _IntakeHistory({required this.entries});

  final List<HydrationEntry> entries;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Today's intake",
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        for (final entry in entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Icon(
                  Icons.water_drop_rounded,
                  size: 18,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Text(
                  '${entry.amountMl} ml',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  entry.time.format(context),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}