import 'package:flutter/material.dart';

import 'reminder_screen.dart';

class GoalScreen extends StatefulWidget {
  const GoalScreen({super.key, this.initialGoal = 2500, this.onContinue});

  final int initialGoal;
  final ValueChanged<int>? onContinue;

  @override
  State<GoalScreen> createState() => _GoalScreenState();
}

class _GoalScreenState extends State<GoalScreen>
    with SingleTickerProviderStateMixin {
  static const int _minGoal = 1000;
  static const int _maxGoal = 5000;
  static const int _step = 100;

  late int _goal;
  double _dragValue = 0.0;

  late final AnimationController _waterAnimationController;

  @override
  void initState() {
    super.initState();

    _goal = _snapToStep(widget.initialGoal.clamp(_minGoal, _maxGoal));

    _waterAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _waterAnimationController.dispose();
    super.dispose();
  }

  int _snapToStep(int value) {
    return ((value - _minGoal) / _step).round() * _step + _minGoal;
  }

  double get _progress => (_goal - _minGoal) / (_maxGoal - _minGoal);

  String get _litres {
    final litres = _goal / 1000;
    return litres == litres.roundToDouble()
        ? '${litres.toInt()} L'
        : '${litres.toStringAsFixed(1)} L';
  }

  void _setGoal(int value) {
    final snapped = _snapToStep(value.clamp(_minGoal, _maxGoal));

    if (snapped == _goal) return;

    setState(() {
      _goal = snapped;
    });
  }

  void _selectPreset(int value) {
    setState(() {
      _goal = value;
    });
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
            _Background(primary: primary, secondary: secondary),

            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
              child: Column(
                children: [
                  _buildTopBar(context, primary),

                  const SizedBox(height: 18),

                  _buildProgressIndicator(context, primary),

                  const SizedBox(height: 28),

                  Text(
                    "What's your\ndaily water goal?",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 30,
                      height: 1.15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                      color: colorScheme.onSurface,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    "Let's set a goal that keeps you\nhydrated and healthy.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),

                  const SizedBox(height: 24),

                  _buildGoalDisplay(context, primary, secondary),

                  const SizedBox(height: 18),

                  SizedBox(
                    height: 370,
                    child: _buildGoalSelector(context, primary, secondary),
                  ),

                  const SizedBox(height: 20),

                  _buildRecommendedCard(context, primary, secondary),

                  const SizedBox(height: 26),

                  Text(
                    'Quick presets',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),

                  const SizedBox(height: 12),

                  _buildPresets(context, primary),

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
        _progressLine(context, primary, active: true),
        _progressCircle(context, '2', true, primary),
        _progressLine(context, primary, active: false),
        _progressCircle(context, '3', false, primary),
        _progressLine(context, primary, active: false),
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

  Widget _progressLine(
    BuildContext context,
    Color primary, {
    required bool active,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 32,
      height: 2,
      color: active
          ? primary.withValues(alpha: 0.55)
          : Theme.of(context).colorScheme.outlineVariant,
    );
  }

  Widget _buildGoalDisplay(
    BuildContext context,
    Color primary,
    Color secondary,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(scale: animation, child: child),
            );
          },
          child: Text(
            _litres,
            key: ValueKey(_goal),
            style: TextStyle(
              fontSize: 48,
              height: 1,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.5,
              foreground: Paint()
                ..shader = LinearGradient(
                  colors: [primary, secondary],
                ).createShader(const Rect.fromLTWH(0, 0, 180, 60)),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${_goal.toStringAsFixed(0)} ml',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildGoalSelector(
    BuildContext context,
    Color primary,
    Color secondary,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildScale(context, primary),

        const SizedBox(width: 18),

        _buildWaterBottle(context, primary, secondary),
      ],
    );
  }

  Widget _buildScale(BuildContext context, Color primary) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 82,
      height: 330,
      child: Stack(
        children: [
          Positioned.fill(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(21, (index) {
                final value = _maxGoal - (index * _step * 2);

                final major = index % 5 == 0;

                return Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (major)
                      Text(
                        '${(value / 1000).toStringAsFixed(value % 1000 == 0 ? 0 : 1)} L',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    const SizedBox(width: 8),
                    Container(
                      width: major ? 30 : 15,
                      height: major ? 2 : 1.5,
                      decoration: BoxDecoration(
                        color: colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),

          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,

              onVerticalDragStart: (details) {
                _dragValue = _goal.toDouble();
              },

              onVerticalDragUpdate: (details) {
                const sensitivity = 6.0;

                _dragValue -= details.delta.dy * sensitivity;

                _setGoal(_dragValue.round());
              },

              onTapDown: (details) {
                final box = context.findRenderObject() as RenderBox;

                final local = box.globalToLocal(details.globalPosition);

                final ratio = 1 - (local.dy / box.size.height);

                final value =
                    _minGoal + (ratio * (_maxGoal - _minGoal)).round();

                _setGoal(value);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaterBottle(
    BuildContext context,
    Color primary,
    Color secondary,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onVerticalDragStart: (details) {
        _dragValue = _goal.toDouble();
      },

      onVerticalDragUpdate: (details) {
        const sensitivity = 6.0;

        _dragValue -= details.delta.dy * sensitivity;

        _setGoal(_dragValue.round());
      },
      onTapDown: (details) {
        final box = context.findRenderObject() as RenderBox;

        final local = box.globalToLocal(details.globalPosition);

        final ratio = 1 - (local.dy / box.size.height);

        final value = _minGoal + (ratio * (_maxGoal - _minGoal)).round();

        _setGoal(value);
      },
      child: SizedBox(
        width: 130,
        height: 330,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bottleHeight = constraints.maxHeight - 10;

            final fillHeight = bottleHeight * _progress;

            return Stack(
              alignment: Alignment.bottomCenter,
              children: [
                // Bottle interior + fluid
                ClipRRect(
                  borderRadius: BorderRadius.circular(48),
                  child: SizedBox(
                    width: 93,
                    height: bottleHeight - 6,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        width: 93,
                        height: fillHeight,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              primary.withValues(alpha: 0.78),
                              primary,
                              secondary,
                            ],
                          ),
                        ),
                        child: fillHeight > 40
                            ? AnimatedBuilder(
                                animation: _waterAnimationController,
                                builder: (context, child) {
                                  return CustomPaint(
                                    painter: _WavePainter(
                                      animation:
                                          _waterAnimationController.value,
                                      color: colorScheme.onPrimary.withValues(
                                        alpha: 0.25,
                                      ),
                                    ),
                                  );
                                },
                              )
                            : null,
                      ),
                    ),
                  ),
                ),

                // Bottle outline
                Container(
                  width: 105,
                  height: bottleHeight,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(54),
                    border: Border.all(color: colorScheme.surface, width: 6),
                    boxShadow: [
                      BoxShadow(
                        color: primary.withValues(alpha: 0.18),
                        blurRadius: 18,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: (bottleHeight * _progress) - 13,
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colorScheme.surface,
                      boxShadow: [
                        BoxShadow(
                          color: primary.withValues(alpha: 0.25),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.water_drop_rounded,
                      color: primary,
                      size: 23,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildRecommendedCard(
    BuildContext context,
    Color primary,
    Color secondary,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: primary.withValues(alpha: 0.10)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primary.withValues(alpha: 0.12),
            ),
            child: Icon(Icons.water_drop_rounded, color: primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recommended starting goal',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '2.5 L per day',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: secondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.info_outline_rounded,
            size: 20,
            color: colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }

  Widget _buildPresets(BuildContext context, Color primary) {
    const presets = [1500, 2000, 2500, 3000];

    return Row(
      children: presets.map((value) {
        final selected = _goal == value;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: value == presets.last ? 0 : 8),
            child: GestureDetector(
              onTap: () => _selectPreset(value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  color: selected
                      ? primary.withValues(alpha: 0.10)
                      : Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selected
                        ? primary
                        : Theme.of(context).colorScheme.outlineVariant,
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    '${value / 1000 % 1 == 0 ? (value / 1000).toInt() : value / 1000} L',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: selected
                          ? primary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
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
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ReminderScreen(dailyGoalMl: _goal),
              ),
            );
          },
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

class _Background extends StatelessWidget {
  const _Background({required this.primary, required this.secondary});

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

class _WavePainter extends CustomPainter {
  _WavePainter({required this.animation, required this.color});

  final double animation;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;

    final path = Path();

    final waveHeight = 4.0;
    final waveLength = size.width;

    path.moveTo(0, waveHeight);

    for (double x = 0; x <= size.width; x += 2) {
      final y =
          waveHeight *
              0.5 *
              (1 + 0.8 * _sin((x / waveLength) * 6.28 + animation * 6.28)) +
          1;

      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  double _sin(double value) {
    // Small approximation so this file does not require
    // importing dart:math just for the wave animation.
    const pi = 3.141592653589793;
    var x = value % (2 * pi);

    if (x > pi) {
      x -= 2 * pi;
    }

    final x2 = x * x;

    return x - (x2 * x) / 6 + (x2 * x2 * x) / 120 - (x2 * x2 * x2 * x) / 5040;
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}
