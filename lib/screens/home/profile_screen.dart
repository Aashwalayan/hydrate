import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../profile/appearance_screen.dart';
import '../profile/about_screen.dart';
import '../profile/account_screen.dart';
import '../profile/hydration_goal_screen.dart';
import '../profile/history_screen.dart';

import '../../services//auth_service.dart';
import '../../services/hydration_service.dart';
import '../../services/hydration_alarm_local_storage.dart';
import '../../services/alarm_service.dart';

import '../../theme/hydrate_theme.dart';
import '../../theme/theme_provider.dart';

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

  File? _profileImage;
  String? _profilePictureUrl;

  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _loadHydrationGoal();
    _loadProfilePicture();
  }

  Future<void> _loadProfilePicture() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString('profile_picture_path');

    if (path == null) return;

    final file = File(path);

    if (!await file.exists()) {
      await prefs.remove('profile_picture_path');
      return;
    }

    if (!mounted) return;

    setState(() {
      _profileImage = file;
    });
  }

  Future<void> _pickProfilePicture() async {
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 800,
    );

    if (pickedFile == null) return;

    final appDirectory = await getApplicationDocumentsDirectory();

    final savedImage = await File(
      pickedFile.path,
    ).copy('${appDirectory.path}/profile_picture.jpg');

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_picture_path', savedImage.path);

    if (!mounted) return;

    setState(() {
      _profileImage = savedImage;
    });
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
        icon: Icons.history_outlined,
        label: 'History',
        onTap: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const HistoryScreen()));
        },
      ),
      ProfileOptionData(
        icon: Icons.local_drink_outlined,
        label: 'Hydration Goal',
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const HydrationGoalScreen()),
          );
        },
      ),
      ProfileOptionData(
        icon: Icons.person_outline_rounded,
        label: 'Account',
        onTap: () async {
          final authService = AuthService();

          final name = await authService.getUserName();
          final email = await authService.getUserEmail();

          if (!context.mounted) return;

          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AccountScreen(
                initialName: name ?? 'User',
                email: email ?? 'No email',

                onNameChanged: (newName) async {
                  final result = await authService.updateName(newName);

                  if (!result.success) {
                    throw Exception(result.message);
                  }
                },

                onChangePassword: (currentPassword, newPassword) async {
                  final result = await authService.changePassword(
                    currentPassword: currentPassword,
                    newPassword: newPassword,
                  );

                  if (!result.success) {
                    throw Exception(result.message);
                  }
                },

                onDeleteAccount: () async {
                  final result = await authService.deleteAccount();

                  if (!result.success) {
                    throw Exception(result.message);
                  }

                  if (!context.mounted) return;

                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil('/', (route) => false);
                },
              ),
            ),
          );
        },
      ),
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
                    profileImage: _profileImage,
                    profilePictureUrl: _profilePictureUrl,
                    hydrationGoalLiters: _today?.goalMl != null
                        ? _today!.goalMl / 1000
                        : 0,
                    isLoadingGoal: _isLoadingGoal,
                    onProfilePictureTap: _pickProfilePicture,
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
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const AboutScreen(),
                            ),
                          );
                        },
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

                      final themeController = ThemeControllerProvider.of(
                        context,
                      );

                      themeController.setSettings(
                        themeMode: ThemeMode.system,
                        hydrateTheme: HydrateTheme.calm,
                      );

                      final prefs = await SharedPreferences.getInstance();
                      final path = prefs.getString('profile_picture_path');

                      if (path != null) {
                        final file = File(path);
                        if (await file.exists()) {
                          await file.delete();
                        }
                      }

                      await prefs.remove('profile_picture_path');

                      final localAlarmStorage = HydrationAlarmLocalStorage();
                      final localAlarm = await localAlarmStorage.loadAlarm();

                      if (localAlarm != null) {
                        await AlarmService.instance.cancelAlarm(
                          localAlarm.id,
                          reminderCount: localAlarm.reminderTimes.length,
                        );
                      }

                      await localAlarmStorage.deleteAlarm();

                      await AuthService().logout();

                      await HydrationAlarmLocalStorage().deleteAlarm();

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
    required this.profileImage,
    required this.profilePictureUrl,
    required this.onProfilePictureTap,
  });

  final String userName;
  final double hydrationGoalLiters;
  final bool isLoadingGoal;

  final File? profileImage;
  final String? profilePictureUrl;
  final VoidCallback onProfilePictureTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: onProfilePictureTap,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                GestureDetector(
                  onTap: onProfilePictureTap,
                  child: CircleAvatar(
                    radius: 44,
                    backgroundColor: colorScheme.primary.withValues(
                      alpha: 0.14,
                    ),
                    backgroundImage: profileImage != null
                        ? FileImage(profileImage!)
                        : profilePictureUrl != null
                        ? NetworkImage(profilePictureUrl!)
                        : null,
                    child: profileImage == null && profilePictureUrl == null
                        ? Text(
                            userName.isNotEmpty
                                ? userName[0].toUpperCase()
                                : '?',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          )
                        : null,
                  ),
                ),

                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: colorScheme.surface, width: 3),
                    ),
                    child: Icon(
                      Icons.camera_alt_rounded,
                      size: 15,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                ),
              ],
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
