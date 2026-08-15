import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/hydration_service.dart';

/// Primary dashboard for today's hydration.
///
/// Hydration data is loaded from the backend through HydrationService.
/// This screen does not own a PageView.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _userName = 'there';
  String _greeting = 'Good evening';

  DailyHydration? _today;

  bool _isLoading = true;
  bool _isAddingWater = false;

  String? _errorMessage;

  // -------------------------------------------------------------------------
  // Reminder mock - will be replaced with real reminder logic next.
  // -------------------------------------------------------------------------

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

    _loadUserData();
    _loadHydrationData();

    // Still mock for now. We'll replace this with the actual reminder
    // settings/notification system after hydration tracking is working.
    _startCountdown();
  }

  // -------------------------------------------------------------------------
  // User
  // -------------------------------------------------------------------------

  Future<void> _loadUserData() async {
    final authService = AuthService();
    final name = await authService.getUserName();

    if (!mounted) return;

    setState(() {
      _userName = name ?? 'there';
      _greeting = _getGreeting();
    });
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;

    if (hour >= 5 && hour < 12) {
      return 'Good morning';
    }

    if (hour >= 12 && hour < 17) {
      return 'Good afternoon';
    }

    return 'Good evening';
  }

  // -------------------------------------------------------------------------
  // Hydration
  // -------------------------------------------------------------------------

  Future<void> _loadHydrationData() async {
    try {
      final service = HydrationService();

      final today = await service.getToday();

      if (!mounted) return;

      setState(() {
        _today = today;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      debugPrint('Hydration loading error: $e');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to load hydration data.';
      });
    }
  }

  Future<void> _addWater(int amountMl) async {
    if (_isAddingWater) return;

    setState(() {
      _isAddingWater = true;
    });

    try {
      final service = HydrationService();

      final updatedToday = await service.addWater(amountMl);

      if (!mounted) return;

      setState(() {
        _today = updatedToday;
        _isAddingWater = false;
      });
    } catch (e) {
      debugPrint('Add water error: $e');

      if (!mounted) return;

      setState(() {
        _isAddingWater = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not add water. Please try again.'),
        ),
      );
    }
  }

  Future<void> _openAddWaterSheet() async {
    if (_isAddingWater) return;

    final amount = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _AddWaterSheet(),
    );

    if (amount == null) return;

    await _addWater(amount);
  }

  // -------------------------------------------------------------------------
  // Reminder - temporary mock
  // -------------------------------------------------------------------------

  void _startCountdown() {
    _countdownTimer?.cancel();

    _countdownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (!mounted) return;

        setState(() {
          if (_reminderSecondsRemaining <= 0) {
            _reminderSecondsRemaining =
                _mockReminderInterval.inSeconds;
          } else {
            _reminderSecondsRemaining -= 1;
          }
        });
      },
    );
  }

  void _handleSkip() {
    setState(() {
      _justSkipped = true;
      _reminderSecondsRemaining =
          _mockReminderInterval.inSeconds;
    });

    Future.delayed(
      const Duration(milliseconds: 900),
      () {
        if (mounted) {
          setState(() {
            _justSkipped = false;
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final currentIntake = _today?.intakeMl ?? 0;
    final dailyGoal = _today?.goalMl ?? 2500;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                20,
                12,
                20,
                120,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _Greeting(
                    userName: _userName,
                    greeting: _greeting,
                  ),

                  const SizedBox(height: 28),

                  if (_errorMessage != null)
                    _ErrorCard(
                      message: _errorMessage!,
                      onRetry: _loadHydrationData,
                    ),

                  _HydrationProgress(
                    currentIntake: currentIntake,
                    dailyGoal: dailyGoal,
                    isLoading: _isLoading,
                  ),

                  const SizedBox(height: 24),

                  _AddWaterButton(
                    onTap: _openAddWaterSheet,
                    isLoading: _isAddingWater,
                  ),

                  const SizedBox(height: 24),

                  _NextReminderCard(
                    secondsRemaining:
                        _reminderSecondsRemaining,
                    totalSeconds:
                        _mockReminderInterval.inSeconds,
                    justSkipped: _justSkipped,
                    onSkip: _handleSkip,
                  ),

                  const SizedBox(height: 28),

                  _IntakeHistory(
                    entries: _today?.entries ?? const [],
                    isLoading: _isLoading,
                  ),
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
  const _Greeting({
    required this.userName,
    required this.greeting,
  });

  final String userName;
  final String greeting;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$greeting, $userName',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Let's stay hydrated today",
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(
              alpha: 0.6,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Error card
// ---------------------------------------------------------------------------

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            Icons.cloud_off_rounded,
            color: colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onErrorContainer,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hydration progress
// ---------------------------------------------------------------------------

class _HydrationProgress extends StatefulWidget {
  const _HydrationProgress({
    required this.currentIntake,
    required this.dailyGoal,
    required this.isLoading,
  });

  final int currentIntake;
  final int dailyGoal;
  final bool isLoading;

  @override
  State<_HydrationProgress> createState() =>
      _HydrationProgressState();
}

class _HydrationProgressState extends State<_HydrationProgress>
    with TickerProviderStateMixin {
  late final AnimationController _loadController;
  late Animation<double> _fillAnimation;
  late final AnimationController _waveController;

  double get _progress {
    if (widget.dailyGoal <= 0) return 0;

    return (widget.currentIntake / widget.dailyGoal)
        .clamp(0.0, 1.0);
  }

  @override
  void initState() {
    super.initState();

    _loadController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fillAnimation = Tween<double>(
      begin: 0,
      end: _progress,
    ).animate(
      CurvedAnimation(
        parent: _loadController,
        curve: Curves.easeOutCubic,
      ),
    );

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _loadController.forward();
  }

  @override
  void didUpdateWidget(
    covariant _HydrationProgress oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.currentIntake != widget.currentIntake ||
        oldWidget.dailyGoal != widget.dailyGoal) {
      final begin = _fillAnimation.value;

      _fillAnimation = Tween<double>(
        begin: begin,
        end: _progress,
      ).animate(
        CurvedAnimation(
          parent: _loadController,
          curve: Curves.easeOutCubic,
        ),
      );

      _loadController
        ..reset()
        ..forward();
    }
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
              color: colorScheme.onSurface.withValues(
                alpha: 0.5,
              ),
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: 220,
            height: 220,
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _fillAnimation,
                _waveController,
              ]),
              builder: (context, child) {
                return CustomPaint(
                  painter: _WaterCirclePainter(
                    fillLevel: _fillAnimation.value,
                    wavePhase:
                        _waveController.value * 2 * math.pi,
                    fillColor: colorScheme.primary,
                    trackColor:
                        colorScheme.onSurface.withValues(
                      alpha: 0.06,
                    ),
                    borderColor:
                        colorScheme.onSurface.withValues(
                      alpha: 0.08,
                    ),
                  ),
                  child: child,
                );
              },
              child: Center(
                child: widget.isLoading
                    ? const CircularProgressIndicator()
                    : Column(
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
                                  (widget.dailyGoal *
                                          _fillAnimation.value)
                                      .round();

                              return Text(
                                '$shownMl ml',
                                style: theme
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      fontWeight:
                                          FontWeight.w700,
                                    ),
                              );
                            },
                          ),

                          Text(
                            '/ ${widget.dailyGoal} ml',
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(
                              color: colorScheme.onSurface
                                  .withValues(alpha: 0.55),
                            ),
                          ),

                          const SizedBox(height: 8),

                          AnimatedBuilder(
                            animation: _fillAnimation,
                            builder: (context, _) {
                              return Text(
                                '${(_fillAnimation.value * 100).round()}%',
                                style: theme.textTheme.titleMedium
                                    ?.copyWith(
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

// ---------------------------------------------------------------------------
// Water circle painter
// ---------------------------------------------------------------------------

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
    final center = Offset(
      size.width / 2,
      size.height / 2,
    );

    final radius = size.width / 2;

    final trackPaint = Paint()..color = trackColor;

    canvas.drawCircle(
      center,
      radius,
      trackPaint,
    );

    canvas.save();

    canvas.clipPath(
      Path()
        ..addOval(
          Rect.fromCircle(
            center: center,
            radius: radius,
          ),
        ),
    );

    final waterHeight =
        size.height * (1 - fillLevel);

    const waveAmplitude = 6.0;
    const waveLength = 90.0;

    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, waterHeight);

    for (double x = 0; x <= size.width; x++) {
      final y = waterHeight +
          waveAmplitude *
              math.sin(
                (x / waveLength * 2 * math.pi) +
                    wavePhase,
              );

      path.lineTo(x, y);
    }

    path
      ..lineTo(size.width, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          fillColor.withValues(alpha: 0.65),
          fillColor.withValues(alpha: 0.85),
        ],
      ).createShader(
        Rect.fromLTWH(
          0,
          0,
          size.width,
          size.height,
        ),
      );

    canvas.drawPath(path, fillPaint);

    canvas.restore();

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = borderColor;

    canvas.drawCircle(
      center,
      radius - 1,
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(
    covariant _WaterCirclePainter oldDelegate,
  ) {
    return oldDelegate.fillLevel != fillLevel ||
        oldDelegate.wavePhase != wavePhase ||
        oldDelegate.fillColor != fillColor;
  }
}

// ---------------------------------------------------------------------------
// Add Water button
// ---------------------------------------------------------------------------

class _AddWaterButton extends StatelessWidget {
  const _AddWaterButton({
    required this.onTap,
    required this.isLoading,
  });

  final VoidCallback onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.primary,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: colorScheme.onPrimary.withValues(
          alpha: 0.18,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            vertical: 18,
          ),
          alignment: Alignment.center,
          child: isLoading
              ? SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: colorScheme.onPrimary,
                  ),
                )
              : Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_rounded,
                      color: colorScheme.onPrimary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Add Water',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(
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

// ---------------------------------------------------------------------------
// Add Water sheet
// ---------------------------------------------------------------------------

class _AddWaterSheet extends StatefulWidget {
  const _AddWaterSheet();

  @override
  State<_AddWaterSheet> createState() =>
      _AddWaterSheetState();
}

class _AddWaterSheetState extends State<_AddWaterSheet> {
  static const List<int> _quickAmounts = [
    150,
    250,
    350,
    500,
  ];

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
        padding: const EdgeInsets.fromLTRB(
          24,
          12,
          24,
          24,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(28),
          ),
          border: Border(
            top: BorderSide(
              color: colorScheme.onSurface.withValues(
                alpha: 0.08,
              ),
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(
                  bottom: 20,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.onSurface
                      .withValues(alpha: 0.15),
                  borderRadius:
                      BorderRadius.circular(4),
                ),
              ),
            ),

            Text(
              'How much did you drink?',
              style: theme.textTheme.titleLarge
                  ?.copyWith(
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
                    selected:
                        _selectedAmount == amount,
                    onTap: () {
                      setState(() {
                        _selectedAmount = amount;
                      });
                    },
                  ),
              ],
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor:
                      colorScheme.primary,
                  foregroundColor:
                      colorScheme.onPrimary,
                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 16,
                  ),
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(16),
                  ),
                ),
                onPressed: _selectedAmount == null
                    ? null
                    : () {
                        Navigator.of(context)
                            .pop(_selectedAmount);
                      },
                child: const Text('Add'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Amount chip
// ---------------------------------------------------------------------------

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
          ? colorScheme.primary.withValues(
              alpha: 0.14,
            )
          : colorScheme.onSurface.withValues(
              alpha: 0.05,
            ),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration:
              const Duration(milliseconds: 180),
          padding:
              const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? colorScheme.primary
                  : colorScheme.onSurface
                      .withValues(alpha: 0.1),
            ),
          ),
          child: Text(
            label,
            style: theme.textTheme.bodyMedium
                ?.copyWith(
              color: selected
                  ? colorScheme.primary
                  : colorScheme.onSurface,
              fontWeight: selected
                  ? FontWeight.w700
                  : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Next reminder
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

    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer
            .withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.onSurface.withValues(
            alpha: 0.06,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'NEXT REMINDER',
                style: theme.textTheme.labelMedium
                    ?.copyWith(
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface
                      .withValues(alpha: 0.55),
                ),
              ),

              AnimatedOpacity(
                opacity: justSkipped ? 1 : 0,
                duration:
                    const Duration(milliseconds: 200),
                child: Text(
                  'Skipped',
                  style: theme.textTheme.labelMedium
                      ?.copyWith(
                    color:
                        colorScheme.primary,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          AnimatedSwitcher(
            duration:
                const Duration(milliseconds: 250),
            child: Text(
              _formatted,
              key: ValueKey(_formatted),
              style: theme.textTheme.displaySmall
                  ?.copyWith(
                fontWeight:
                    FontWeight.w700,
                fontFeatures: const [
                  FontFeature.tabularFigures(),
                ],
              ),
            ),
          ),

          const SizedBox(height: 4),

          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.water_drop_outlined,
                    size: 18,
                    color: colorScheme
                        .onSurface
                        .withValues(
                      alpha: 0.6,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Drink 250 ml',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(
                      color: colorScheme
                          .onSurface
                          .withValues(
                        alpha: 0.7,
                      ),
                    ),
                  ),
                ],
              ),

              TextButton(
                onPressed: onSkip,
                style:
                    TextButton.styleFrom(
                  foregroundColor:
                      colorScheme.onSurface
                          .withValues(
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
  const _IntakeHistory({
    required this.entries,
    required this.isLoading,
  });

  final List<HydrationEntry> entries;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          "Today's intake",
          style: theme.textTheme.titleMedium
              ?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 10),

        if (isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          )
        else if (entries.isEmpty)
          Padding(
            padding:
                const EdgeInsets.symmetric(
              vertical: 20,
            ),
            child: Center(
              child: Text(
                'No water logged yet today.',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(
                  color: colorScheme.onSurface
                      .withValues(alpha: 0.5),
                ),
              ),
            ),
          )
        else
          for (final entry in entries)
            Padding(
              padding:
                  const EdgeInsets.symmetric(
                vertical: 6,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.water_drop_rounded,
                    size: 18,
                    color:
                        colorScheme.primary,
                  ),

                  const SizedBox(width: 10),

                  Text(
                    '${entry.amountMl} ml',
                    style: theme.textTheme
                        .bodyMedium
                        ?.copyWith(
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),

                  const Spacer(),

                  Text(
                    TimeOfDay.fromDateTime(
                      entry.timestamp,
                    ).format(context),
                    style: theme.textTheme
                        .bodySmall
                        ?.copyWith(
                      color: colorScheme
                          .onSurface
                          .withValues(
                        alpha: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
      ],
    );
  }
}