import 'package:flutter/material.dart';

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.24),
            theme.colorScheme.surface,
            theme.colorScheme.secondary.withValues(alpha: 0.14),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth < 420 ? 20.0 : 28.0;

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                24,
                horizontalPadding,
                24,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 48,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 58,
                              height: 58,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Icon(
                                Icons.water_drop_rounded,
                                color: theme.colorScheme.primary,
                                size: 30,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(title, style: theme.textTheme.headlineSmall),
                            const SizedBox(height: 10),
                            Text(
                              subtitle,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 28),
                            child,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
