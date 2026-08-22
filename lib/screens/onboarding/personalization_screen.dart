import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../theme/hydrate_theme.dart';
import '../../theme/theme_controller.dart';
import '../../theme/theme_provider.dart';
import '../home/main_screen.dart';

class PersonalizationScreen extends StatefulWidget {
  const PersonalizationScreen({
    super.key,
    this.initialThemeMode = ThemeMode.system,
    this.initialTheme = HydrateTheme.calm,
    this.onFinish,
  });

  final ThemeMode initialThemeMode;
  final HydrateTheme initialTheme;
  final void Function(ThemeMode themeMode, HydrateTheme theme)? onFinish;

  @override
  State<PersonalizationScreen> createState() => _PersonalizationScreenState();
}

class _PersonalizationScreenState extends State<PersonalizationScreen> {
  ThemeController get _themeController => ThemeControllerProvider.of(context);

  late ThemeMode _themeMode;
  late HydrateTheme _theme;

  @override
  void initState() {
    super.initState();

    _themeMode = widget.initialThemeMode;
    _theme = widget.initialTheme;
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('theme_mode', _themeMode.name);
    await prefs.setString('hydrate_theme', _theme.name);

    // Mark onboarding as completed.
    await prefs.setBool('onboarding_complete', true);

    _themeController.setSettings(themeMode: _themeMode, hydrateTheme: _theme);

    widget.onFinish?.call(_themeMode, _theme);

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const MainScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final primary = colorScheme.primary;
    final secondary = colorScheme.secondary;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Stack(
          children: [
            _PersonalizationBackground(primary: primary, secondary: secondary),

            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
              child: Column(
                children: [
                  _buildTopBar(context, primary),

                  const SizedBox(height: 18),

                  _buildProgressIndicator(context, primary),

                  const SizedBox(height: 30),

                  _buildHeader(context, primary),

                  const SizedBox(height: 30),

                  _buildAppearanceSection(context, primary),

                  const SizedBox(height: 24),

                  _buildThemeSection(context, primary, secondary),

                  const SizedBox(height: 28),

                  _buildPreview(context, primary, secondary),

                  const SizedBox(height: 30),

                  _buildFinishButton(context, primary, secondary),
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
        _progressLine(context, primary),
        _progressCircle(context, '2', false, primary),
        _progressLine(context, primary),
        _progressCircle(context, '3', false, primary),
        _progressLine(context, primary),
        _progressCircle(context, '4', true, primary),
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
          color: active ? Colors.white : colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _progressLine(BuildContext context, Color primary) {
    return Container(
      width: 32,
      height: 2,
      color: primary.withValues(alpha: 0.55),
    );
  }

  Widget _buildHeader(BuildContext context, Color primary) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                primary.withValues(alpha: 0.18),
                const Color(0xFFA78BFA).withValues(alpha: 0.14),
              ],
            ),
          ),
          child: Icon(Icons.auto_awesome_rounded, size: 38, color: primary),
        ),

        const SizedBox(height: 20),

        Text(
          'Make Hydrate yours.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 30,
            height: 1.15,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: colorScheme.onSurface,
          ),
        ),

        const SizedBox(height: 10),

        Text(
          'Choose a look that feels right for you.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            height: 1.5,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildAppearanceSection(BuildContext context, Color primary) {
    final colorScheme = Theme.of(context).colorScheme;

    return _sectionCard(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Appearance',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            'You can change this anytime in Settings.',
            style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              _appearanceOption(
                context,
                icon: Icons.light_mode_rounded,
                label: 'Light',
                mode: ThemeMode.light,
                primary: primary,
              ),
              const SizedBox(width: 10),
              _appearanceOption(
                context,
                icon: Icons.dark_mode_rounded,
                label: 'Dark',
                mode: ThemeMode.dark,
                primary: primary,
              ),
              const SizedBox(width: 10),
              _appearanceOption(
                context,
                icon: Icons.brightness_auto_rounded,
                label: 'System',
                mode: ThemeMode.system,
                primary: primary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _appearanceOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required ThemeMode mode,
    required Color primary,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final selected = _themeMode == mode;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _themeMode = mode;
          });
          _themeController.setThemeMode(mode);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: selected
                ? primary.withValues(alpha: 0.10)
                : colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? primary : colorScheme.outlineVariant,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 24,
                color: selected ? primary : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected ? primary : colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeSection(
    BuildContext context,
    Color primary,
    Color secondary,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return _sectionCard(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hydrate style',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            'Pick a subtle accent for your app.',
            style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
          ),

          const SizedBox(height: 18),

          ...HydrateTheme.values.asMap().entries.map((entry) {
            final index = entry.key;
            final theme = entry.value;
            final data = HydrateThemes.get(theme);

            return Column(
              children: [
                _themeOption(
                  context,
                  theme: theme,
                  primary: data.primary,
                  secondary: data.secondary,
                  title: data.name,
                  subtitle: data.description,
                ),

                if (index != HydrateTheme.values.length - 1)
                  const SizedBox(height: 10),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _themeOption(
    BuildContext context, {
    required HydrateTheme theme,
    required Color primary,
    required Color secondary,
    required String title,
    required String subtitle,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final selected = _theme == theme;

    return GestureDetector(
      onTap: () {
        setState(() {
          _theme = theme;
        });
        _themeController.setHydrateTheme(theme);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: selected
              ? primary.withValues(alpha: 0.08)
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: selected ? primary : colorScheme.outlineVariant,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [primary, secondary],
                ),
              ),
              child: const Icon(Icons.water_drop_rounded, color: Colors.white),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 3),
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

            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 23,
              height: 23,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? primary : colorScheme.outline,
                  width: 2,
                ),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 11,
                        height: 11,
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
    );
  }

  Widget _buildPreview(BuildContext context, Color primary, Color secondary) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primary.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [primary, secondary]),
            ),
            child: const Icon(
              Icons.water_drop_rounded,
              color: Colors.white,
              size: 27,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Looking good.',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your Hydrate experience is ready.',
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          Icon(Icons.check_circle_rounded, color: secondary, size: 25),
        ],
      ),
    );
  }

  Widget _sectionCard(BuildContext context, {required Widget child}) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.7),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildFinishButton(
    BuildContext context,
    Color primary,
    Color secondary,
  ) {
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
          onPressed: _finish,
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Finish setup',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              SizedBox(width: 10),
              Icon(Icons.check_rounded, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class _PersonalizationBackground extends StatelessWidget {
  const _PersonalizationBackground({
    required this.primary,
    required this.secondary,
  });

  final Color primary;
  final Color secondary;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return IgnorePointer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary.withValues(alpha: 0.12),
              colorScheme.surface,
              colorScheme.secondary.withValues(alpha: 0.09),
            ],
          ),
        ),
      ),
    );
  }
}
