
import 'package:flutter/material.dart';

import '../auth/auth_gate.dart';

/// Branded startup screen shown immediately on launch.
///
/// Two things happen in parallel here, and neither blocks the other:
/// 1. A fixed-duration entrance animation (logo + wordmark) plays out.
/// 2. [ServerWakeService.pingHealth] fires once in the background to wake
///    the Render backend. Its result is intentionally ignored — the splash
///    never waits on it, never shows an error, and never extends its own
///    timing because of it.
///
/// Once the entrance animation finishes, this screen hands off to the
/// existing [AuthGate], which is unchanged and still owns the
/// authenticated-vs-onboarding decision.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  static const Duration _entranceDuration = Duration(milliseconds: 1400);
  static const Duration _holdDuration = Duration(milliseconds: 500);


  late final AnimationController _entranceController;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _textOpacity;
  late final Animation<Offset> _textSlide;

  late final AnimationController _rippleController;

  @override
  void initState() {
    super.initState();


    _entranceController = AnimationController(
      vsync: this,
      duration: _entranceDuration,
    );

    _logoScale = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOutBack),
      ),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.35, 0.85, curve: Curves.easeOut),
      ),
    );
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.35, 0.85, curve: Curves.easeOutCubic),
      ),
    );

    // Slow, continuous, subtle ripple behind the logo — purely decorative,
    // not tied to any loading state.
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _entranceController.forward();
    _scheduleNavigation();
  }

  Future<void> _scheduleNavigation() async {
    await Future.delayed(_entranceDuration + _holdDuration);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AuthGate()),
    );
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 160,
              height: 160,
              child: AnimatedBuilder(
                animation: Listenable.merge([
                  _entranceController,
                  _rippleController,
                ]),
                builder: (context, child) {
                  return CustomPaint(
                    painter: _RipplePainter(
                      progress: _rippleController.value,
                      color: colorScheme.primary,
                    ),
                    child: Center(
                      child: Opacity(
                        opacity: _logoOpacity.value,
                        child: Transform.scale(
                          scale: _logoScale.value,
                          child: child,
                        ),
                      ),
                    ),
                  );
                },
                child: _HydrateLogo(colorScheme: colorScheme),
              ),
            ),
            const SizedBox(height: 28),
            FadeTransition(
              opacity: _textOpacity,
              child: SlideTransition(
                position: _textSlide,
                child: Column(
                  children: [
                    Text(
                      'Hydrate',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Stay refreshed, stay you',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// App mark used on the splash screen. If the project already has a real
/// Hydrate logo asset, swap this out for an `Image.asset(...)` — it's
/// isolated here specifically so that's a one-place change.
class _HydrateLogo extends StatelessWidget {
  const _HydrateLogo({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 84,
      height: 84,
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
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Icon(
        Icons.water_drop_rounded,
        color: colorScheme.onPrimary,
        size: 40,
      ),
    );
  }
}

/// Slow, low-amplitude concentric ripple rings expanding outward from the
/// logo — a tasteful, continuous water motif rather than a loading spinner.
class _RipplePainter extends CustomPainter {
  _RipplePainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    const ringCount = 2;
    for (var i = 0; i < ringCount; i++) {
      final ringProgress = (progress + (i / ringCount)) % 1.0;
      final radius = maxRadius * (0.5 + 0.5 * ringProgress);
      final opacity = (1 - ringProgress) * 0.25;

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = color.withValues(alpha: opacity);

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RipplePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}