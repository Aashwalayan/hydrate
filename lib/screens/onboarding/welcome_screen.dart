import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

Future<void> wakeServer() async {
  try {
    await http.get(
      Uri.parse('https://hydrate-vor8.onrender.com'),
    );
  } catch (_) {
    // we dont actually need to have an error here, since the server is just being woken up and we don't care about the response
  }
}

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({
    super.key,
    this.onGetStarted,
  });

  final VoidCallback? onGetStarted;

  static const Color _primary = Color(0xFF4FC3E8);
  static const Color _secondary = Color(0xFF7FD8C7);

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  void initState() {
  super.initState();
  wakeServer();
}
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final surface = isDark
        ? const Color(0xFF101820)
        : const Color(0xFFF5FAFB);

    final primary = isDark
        ? const Color(0xFF5FD3F3)
        : WelcomeScreen._primary;

    final secondary = isDark
        ? const Color(0xFF6FE0C9)
        : WelcomeScreen._secondary;

    return Scaffold(
      backgroundColor: surface,
      body: SafeArea(
        child: Stack(
          children: [
            _Background(
              primary: primary,
              secondary: secondary,
              isDark: isDark,
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(
                28,
                28,
                28,
                28,
              ),
              child: Column(
                children: [
                  const Spacer(),

                  _buildLogo(
                    primary,
                    secondary,
                  ),

                  const SizedBox(height: 32),

                  Text(
                    'Welcome to\nHydrate',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 40,
                      height: 1.08,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.2,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),

                  const SizedBox(height: 18),

                  Text(
                    'A simple way to build a better\nhydration habit, one sip at a time.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 17,
                      height: 1.55,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),

                  const SizedBox(height: 34),

                  _buildFeatureRow(
                    context,
                    icon: Icons.water_drop_rounded,
                    title: 'Track your water',
                    subtitle: 'See your progress throughout the day.',
                    primary: primary,
                  ),

                  const SizedBox(height: 12),

                  _buildFeatureRow(
                    context,
                    icon: Icons.notifications_none_rounded,
                    title: 'Gentle reminders',
                    subtitle: 'Never forget to take another sip.',
                    primary: primary,
                  ),

                  const SizedBox(height: 12),

                  _buildFeatureRow(
                    context,
                    icon: Icons.insights_rounded,
                    title: 'Understand your habits',
                    subtitle: 'Look back and see your progress over time.',
                    primary: primary,
                  ),

                  const Spacer(),

                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            primary,
                            secondary,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: primary.withValues(
                              alpha: 0.25,
                            ),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: widget.onGetStarted,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            Text(
                              'Get Started',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(width: 10),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 22,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  Text(
                    'Let’s make hydration a habit.',
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo(
    Color primary,
    Color secondary,
  ) {
    return Container(
      width: 118,
      height: 118,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primary.withValues(alpha: 0.18),
            secondary.withValues(alpha: 0.16),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.14),
            blurRadius: 28,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                primary,
                secondary,
              ],
            ),
          ),
          child: const Icon(
            Icons.water_drop_rounded,
            color: Colors.white,
            size: 42,
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color primary,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 13,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: primary.withValues(alpha: 0.10),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: primary,
              size: 22,
            ),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
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
}

class _Background extends StatelessWidget {
  const _Background({
    required this.primary,
    required this.secondary,
    required this.isDark,
  });

  final Color primary;
  final Color secondary;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final surface = isDark
        ? const Color(0xFF101820)
        : const Color(0xFFF5FAFB);

    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                primary.withValues(
                  alpha: isDark ? 0.20 : 0.12,
                ),
                surface,
                secondary.withValues(
                  alpha: isDark ? 0.16 : 0.09,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}