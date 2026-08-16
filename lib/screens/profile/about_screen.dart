import 'package:flutter/material.dart';

import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _contactFeedback(BuildContext context) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'projects@aashwalayan.in',
      query: 'subject=Hydrate Feedback',
    );

    final launched = await launchUrl(emailUri);

    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open your email app.')),
      );
    }
  }

  void _rateHydrate(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Rating Hydrate is coming soon.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _viewSourceCode() async {
    final Uri githubUri = Uri.parse('https://github.com/Aashwalayan/hydrate');

    await launchUrl(githubUri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primary = colorScheme.primary;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildTopBar(context),

                  const SizedBox(height: 28),

                  _buildHeader(context, primary),

                  const SizedBox(height: 32),

                  _buildSectionLabel(context, 'ABOUT HYDRATE'),

                  const SizedBox(height: 10),

                  _buildInfoCard(
                    context,
                    icon: Icons.water_drop_rounded,
                    title: 'What is Hydrate?',
                    text:
                        'Hydrate is a simple hydration companion designed to '
                        'help you understand your daily water goal, log water '
                        'quickly, and build a healthier hydration habit.',
                    primary: primary,
                  ),

                  const SizedBox(height: 28),

                  _buildSectionLabel(context, 'THE STORY'),

                  const SizedBox(height: 10),

                  _buildStoryCard(context, primary),

                  const SizedBox(height: 28),

                  _buildSectionLabel(context, 'WHAT YOU CAN DO'),

                  const SizedBox(height: 10),

                  _buildFeaturesCard(context, primary),

                  const SizedBox(height: 28),

                  _buildSectionLabel(context, 'MORE'),

                  const SizedBox(height: 10),

                  _buildLinksCard(context, primary),

                  const SizedBox(height: 30),

                  _buildFooter(context),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Material(
          color: colorScheme.onSurface.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => Navigator.of(context).pop(),
            child: const SizedBox(
              width: 44,
              height: 44,
              child: Icon(Icons.arrow_back_rounded),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, Color primary) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: primary.withValues(alpha: 0.12),
          ),
          child: Icon(Icons.water_drop_rounded, color: primary, size: 27),
        ),
        const SizedBox(height: 18),
        Text(
          'About Hydrate',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          'A simple way to stay on top of your water.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Version 1.0.0',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.45),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(BuildContext context, String label) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          letterSpacing: 1.1,
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface.withValues(alpha: 0.48),
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String text,
    required Color primary,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return _card(
      context,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _iconBox(context, icon, primary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    text,
                    style: theme.textTheme.bodySmall?.copyWith(
                      height: 1.45,
                      color: colorScheme.onSurfaceVariant,
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

  Widget _buildStoryCard(BuildContext context, Color primary) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return _card(
      context,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 19, 18, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _iconBox(context, Icons.favorite_border_rounded, primary),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Why I made Hydrate',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'I’ve been coding for quite a while, and one day my friend '
              'pointed out that, despite all the things I’ve built, I had '
              'never actually made an app for her.',
              style: theme.textTheme.bodySmall?.copyWith(
                height: 1.5,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'So... I made one.',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'What started as a little challenge turned into Hydrate — '
              'something useful, something I could actually finish, and '
              'something made for a friend.',
              style: theme.textTheme.bodySmall?.copyWith(
                height: 1.5,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesCard(BuildContext context, Color primary) {
    return _card(
      context,
      child: Column(
        children: [
          _featureRow(
            context,
            Icons.flag_outlined,
            'Personalized goals',
            'A hydration goal tailored to you.',
            primary,
          ),
          _divider(context),
          _featureRow(
            context,
            Icons.add_circle_outline_rounded,
            'Quick water logging',
            'Log your water without getting in the way.',
            primary,
          ),
          _divider(context),
          _featureRow(
            context,
            Icons.insights_outlined,
            'Progress tracking',
            'See how you are doing throughout the day.',
            primary,
          ),
          _divider(context),
          _featureRow(
            context,
            Icons.notifications_none_rounded,
            'Reminders',
            'Helpful nudges when you need them.',
            primary,
          ),
        ],
      ),
    );
  }

  Widget _featureRow(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    Color primary,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          _iconBox(context, icon, primary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
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

  Widget _buildLinksCard(BuildContext context, Color primary) {
  return _card(
    context,
    child: Column(
      children: [
        _linkRow(
          context,
          Icons.mail_outline_rounded,
          'Contact / Feedback',
          primary,
          () => _contactFeedback(context),
        ),
        _divider(context),
        _linkRow(
          context,
          Icons.star_border_rounded,
          'Rate Hydrate',
          primary,
          () => _rateHydrate(context),
        ),
        _divider(context),
        _linkRow(
          context,
          Icons.code_rounded,
          'View source code',
          primary,
          _viewSourceCode,
        ),
      ],
    ),
  );
}

  Widget _linkRow(
  BuildContext context,
  IconData icon,
  String title,
  Color primary,
  VoidCallback onTap,
) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;

  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        child: Row(
          children: [
            _iconBox(context, icon, primary),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: colorScheme.onSurface.withValues(alpha: 0.35),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildFooter(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        Text(
          'i hope you like this app vats.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.5),
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '© 2026 Hydrate',
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.35),
          ),
        ),
      ],
    );
  }

  Widget _iconBox(BuildContext context, IconData icon, Color primary) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(icon, size: 21, color: primary),
    );
  }

  Widget _card(BuildContext context, {required Widget child}) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.onSurface.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.onSurface.withValues(alpha: 0.06),
        ),
      ),
      child: child,
    );
  }

  Widget _divider(BuildContext context) {
    return Divider(
      height: 1,
      indent: 72,
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06),
    );
  }
}
