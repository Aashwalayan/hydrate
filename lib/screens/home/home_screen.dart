import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary.withValues(alpha: 0.18),
              theme.colorScheme.surface,
              theme.colorScheme.secondary.withValues(alpha: 0.12),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.water_drop_rounded,
                          size: 42,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Welcome to Hydrate',
                          style: theme.textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'This is a placeholder home screen. Once your Node/Express backend is connected, authenticated users can land here with real profile and hydration data.',
                          style: theme.textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
