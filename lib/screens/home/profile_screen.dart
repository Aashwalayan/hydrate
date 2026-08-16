import 'package:flutter/material.dart';

import '../profile/appearance_screen.dart';

import '../../services//auth_service.dart';
import '../../services/hydration_service.dart';

/// Mock model for a single tappable profile option row.
class ProfileOptionData {
  const ProfileOptionData({
    required this.icon,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
}

/// Profile screen — houses identity plus all app settings/preferences.
/// There is intentionally no separate Settings tab; everything
/// configuration-related lives here.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName = 'User';

  DailyHydration? _today;
  bool _isLoadingGoal = true;

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _loadHydrationGoal();
  }

  Future<void> _loadUserName() async {
    final fullName = await AuthService().getUserName();

    if (!mounted) return;

    final firstName = fullName?.trim().split(' ').first;

    setState(() {
      _userName = (firstName == null || firstName.isEmpty) ? 'User' : firstName;
    });
  }

  Future<void> _loadHydrationGoal() async {
    final service = HydrationService();

    // Show cached data immediately.
    final cachedToday = await service.getCachedToday();

    if (cachedToday != null && mounted) {
      setState(() {
        _today = cachedToday;
        _isLoadingGoal = false;
      });
    }

    // Refresh in the background.
    try {
      final today = await service.getToday();

      if (!mounted) return;

      setState(() {
        _today = today;
        _isLoadingGoal = false;
      });
    } catch (e) {
      debugPrint('Profile hydration loading error: $e');

      if (!mounted) return;

      // Keep cached data if backend isn't available.
      if (cachedToday != null) return;

      setState(() {
        _isLoadingGoal = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final personalizationOptions = [
      ProfileOptionData(
        icon: Icons.palette_outlined,
        label: 'Appearance',
        onTap: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const AppearanceScreen()));
        },
      ),
      ProfileOptionData(
        icon: Icons.notifications_outlined,
        label: 'Notifications',
      ),
      ProfileOptionData(
        icon: Icons.local_drink_outlined,
        label: 'Hydration Goal',
      ),
      ProfileOptionData(icon: Icons.person_outline_rounded, label: 'Account'),
    ];

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Text(
                    'Profile',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 28),

                  _ProfileHeader(
                    userName: _userName,
                    hydrationGoalLiters: _today?.goalMl != null
                        ? _today!.goalMl / 1000
                        : 0,
                    isLoadingGoal: _isLoadingGoal,
                  ),

                  const SizedBox(height: 32),
                  _ProfileSection(
                    title: 'Personalization',
                    options: personalizationOptions,
                  ),
                  const SizedBox(height: 24),
                  _ProfileSection(
                    title: null,
                    options: [
                      ProfileOptionData(
                        icon: Icons.info_outline_rounded,
                        label: 'About Hydrate',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _LogOutButton(
                    onTap: () async {
                      final shouldLogout = await showDialog<bool>(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text('Log out?'),
                            content: const Text(
                              'You will need to sign in again to access your Hydrate account.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                child: const Text('Log out'),
                              ),
                            ],
                          );
                        },
                      );

                      if (shouldLogout != true) return;

                      await AuthService().logout();

                      if (!context.mounted) return;

                      Navigator.of(
                        context,
                      ).pushNamedAndRemoveUntil('/', (route) => false);
                    },
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

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.userName,
    required this.hydrationGoalLiters,
    required this.isLoadingGoal,
  });

  final String userName;
  final double hydrationGoalLiters;
  final bool isLoadingGoal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 44,
            backgroundColor: colorScheme.primary.withValues(alpha: 0.14),
            child: Text(
              userName.isNotEmpty ? userName[0].toUpperCase() : '?',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            userName,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.water_drop_rounded,
                  size: 16,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  isLoadingGoal
                      ? 'Hydration goal · Loading...'
                      : 'Hydration goal · ${hydrationGoalLiters.toStringAsFixed(1)} L',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface.withValues(alpha: 0.75),
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

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({required this.title, required this.options});

  final String? title;
  final List<ProfileOptionData> options;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              title!,
              style: theme.textTheme.labelMedium?.copyWith(
                letterSpacing: 1,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
        Container(
          decoration: BoxDecoration(
            color: colorScheme.onSurface.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colorScheme.onSurface.withValues(alpha: 0.06),
            ),
          ),
          child: Column(
            children: [
              for (var i = 0; i < options.length; i++) ...[
                _ProfileOption(data: options[i]),
                if (i != options.length - 1)
                  Divider(
                    height: 1,
                    indent: 52,
                    color: colorScheme.onSurface.withValues(alpha: 0.06),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileOption extends StatelessWidget {
  const _ProfileOption({required this.data});

  final ProfileOptionData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: data.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(
                data.icon,
                size: 20,
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  data.label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: colorScheme.onSurface.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogOutButton extends StatelessWidget {
  const _LogOutButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout_rounded, size: 18, color: colorScheme.error),
              const SizedBox(width: 8),
              Text(
                'Log out',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
