import 'dart:math' as math;

import 'package:flutter/material.dart';

class HydrationProgress extends StatefulWidget {
  const HydrationProgress({
    super.key,
    required this.currentIntake,
    required this.dailyGoal,
    required this.isLoading,
  });

  final int currentIntake;
  final int dailyGoal;
  final bool isLoading;

  @override
  State<HydrationProgress> createState() => _HydrationProgressState();
}

class _HydrationProgressState extends State<HydrationProgress>
    with TickerProviderStateMixin {
  late final AnimationController _loadController;
  late Animation<double> _fillAnimation;
  late final AnimationController _waveController;

  double get _progress {
    if (widget.dailyGoal <= 0) return 0;

    return (widget.currentIntake / widget.dailyGoal).clamp(0.0, 1.0);
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
  void didUpdateWidget(covariant HydrationProgress oldWidget) {
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
              color: colorScheme.onSurface.withValues(alpha: 0.5),
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
                    wavePhase: _waveController.value * 2 * math.pi,
                    fillColor: colorScheme.primary,
                    trackColor: colorScheme.onSurface.withValues(
                      alpha: 0.06,
                    ),
                    borderColor: colorScheme.onSurface.withValues(
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
                                style:
                                    theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              );
                            },
                          ),

                          Text(
                            '/ ${widget.dailyGoal} ml',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.55,
                              ),
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

    final trackPaint = Paint()
      ..color = trackColor;

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

    final waterHeight = size.height * (1 - fillLevel);

    const waveAmplitude = 6.0;
    const waveLength = 90.0;

    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, waterHeight);

    for (double x = 0; x <= size.width; x++) {
      final y =
          waterHeight +
          waveAmplitude *
              math.sin(
                (x / waveLength * 2 * math.pi) + wavePhase,
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

    canvas.drawPath(
      path,
      fillPaint,
    );

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