import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../theme/hydrate_theme.dart';
import '../../theme/theme_controller.dart';
import '../../theme/theme_provider.dart';

class AppearanceScreen extends StatefulWidget {
  const AppearanceScreen({super.key});

  @override
  State<AppearanceScreen> createState() => _AppearanceScreenState();
}

class _AppearanceScreenState extends State<AppearanceScreen> {
  ThemeController get _themeController => ThemeControllerProvider.of(context);

  ThemeMode _themeMode = ThemeMode.system;
  HydrateTheme _theme = HydrateTheme.calm;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    final storedThemeMode = prefs.getString('theme_mode');
    final storedTheme = prefs.getString('hydrate_theme');

    ThemeMode themeMode = ThemeMode.system;
    HydrateTheme hydrateTheme = HydrateTheme.calm;

    if (storedThemeMode != null) {
      themeMode = ThemeMode.values.firstWhere(
        (mode) => mode.name == storedThemeMode,
        orElse: () => ThemeMode.system,
      );
    }

    if (storedTheme != null) {
      hydrateTheme = HydrateTheme.values.firstWhere(
        (theme) => theme.name == storedTheme,
        orElse: () => HydrateTheme.calm,
      );
    }

    if (!mounted) return;

    setState(() {
      _themeMode = themeMode;
      _theme = hydrateTheme;
      _isLoading = false;
    });
  }

  Future<void> _setThemeMode(ThemeMode mode) async {
    setState(() {
      _themeMode = mode;
    });

    _themeController.setThemeMode(mode);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', mode.name);
  }

  Future<void> _setHydrateTheme(HydrateTheme theme) async {
    setState(() {
      _theme = theme;
    });

    _themeController.setHydrateTheme(theme);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('hydrate_theme', theme.name);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final themeData = HydrateThemes.get(_theme);
    final isDark = theme.brightness == Brightness.dark;

    final primary = isDark ? themeData.darkPrimary : themeData.primary;
    final secondary = isDark ? themeData.darkSecondary : themeData.secondary;

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

                  _buildSectionLabel(context, 'DISPLAY MODE'),

                  const SizedBox(height: 10),

                  _buildAppearanceCard(context, primary),

                  const SizedBox(height: 28),

                  _buildSectionLabel(context, 'HYDRATE STYLE'),

                  const SizedBox(height: 10),

                  _buildHydrateStyleCard(context, primary),
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
          child: Icon(Icons.palette_outlined, color: primary, size: 26),
        ),
        const SizedBox(height: 18),
        Text(
          'Appearance',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          'Customize how Hydrate looks and feels.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
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

  Widget _buildAppearanceCard(BuildContext context, Color primary) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        children: [
          _appearanceOption(
            context,
            icon: Icons.light_mode_rounded,
            title: 'Light',
            subtitle: 'Always use light mode',
            mode: ThemeMode.light,
            primary: primary,
          ),
          _divider(context),
          _appearanceOption(
            context,
            icon: Icons.dark_mode_rounded,
            title: 'Dark',
            subtitle: 'Easy on the eyes',
            mode: ThemeMode.dark,
            primary: primary,
          ),
          _divider(context),
          _appearanceOption(
            context,
            icon: Icons.brightness_auto_rounded,
            title: 'System',
            subtitle: 'Follow your device setting',
            mode: ThemeMode.system,
            primary: primary,
          ),
        ],
      ),
    );
  }

  Widget _appearanceOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required ThemeMode mode,
    required Color primary,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selected = _themeMode == mode;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _setThemeMode(mode),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: selected
                      ? primary.withValues(alpha: 0.12)
                      : colorScheme.onSurface.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  icon,
                  size: 21,
                  color: selected ? primary : colorScheme.onSurfaceVariant,
                ),
              ),
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
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected
                        ? primary
                        : colorScheme.onSurface.withValues(alpha: 0.22),
                    width: 2,
                  ),
                ),
                child: selected
                    ? Center(
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: primary,
                          ),
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHydrateStyleCard(BuildContext context, Color primary) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        children: [
          _themeOption(
            context,
            theme: HydrateTheme.calm,
            title: 'Calm Water',
            subtitle: 'Soft cyan & seafoam',
          ),
          _divider(context),
          _themeOption(
            context,
            theme: HydrateTheme.ocean,
            title: 'Ocean',
            subtitle: 'Cool blue & aqua',
          ),
          _divider(context),
          _themeOption(
            context,
            theme: HydrateTheme.mist,
            title: 'Mist',
            subtitle: 'Blue & muted lavender',
          ),
          _divider(context),
          _themeOption(
            context,
            theme: HydrateTheme.mint,
            title: 'Mint',
            subtitle: 'Fresh green & teal',
          ),
          _divider(context),
          _themeOption(
            context,
            theme: HydrateTheme.lavender,
            title: 'Lavender',
            subtitle: 'Soft purple & pink',
          ),
          _divider(context),
          _themeOption(
            context,
            theme: HydrateTheme.sunset,
            title: 'Sunset',
            subtitle: 'Warm orange & coral',
          ),
          _divider(context),
          _themeOption(
            context,
            theme: HydrateTheme.berry,
            title: 'Berry',
            subtitle: 'Pink & vibrant purple',
          ),
          _divider(context),
          _themeOption(
            context,
            theme: HydrateTheme.midnight,
            title: 'Midnight',
            subtitle: 'Deep indigo & cyan',
          ),
        ],
      ),
    );
  }

  Widget _themeOption(
    BuildContext context, {
    required HydrateTheme theme,
    required String title,
    required String subtitle,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final selected = _theme == theme;

    final themeData = HydrateThemes.get(theme);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final primary = isDark ? themeData.darkPrimary : themeData.primary;
    final secondary = isDark ? themeData.darkSecondary : themeData.secondary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _setHydrateTheme(theme),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(13),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [primary, secondary],
                  ),
                ),
                child: const Icon(
                  Icons.water_drop_rounded,
                  color: Colors.white,
                  size: 21,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected
                        ? primary
                        : colorScheme.onSurface.withValues(alpha: 0.22),
                    width: 2,
                  ),
                ),
                child: selected
                    ? Center(
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: primary,
                          ),
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
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
