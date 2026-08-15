import 'dart:ui';

import 'package:flutter/material.dart';

/// Data for a single destination in [HydrateBottomNavBar].
class HydrateNavDestination {
  const HydrateNavDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

/// Reusable, theme-driven, glass-style floating bottom navigation bar.
///
/// This widget is intentionally decoupled from routing. A parent navigation
/// container (e.g. one hosting a `PageView` + `PageController`) owns the
/// selected index and simply passes it in, along with a callback for when
/// the user taps a destination:
///
/// ```dart
/// HydrateBottomNavBar(
///   currentIndex: _pageController.page?.round() ?? 0,
///   onItemSelected: (index) {
///     _pageController.animateToPage(
///       index,
///       duration: const Duration(milliseconds: 300),
///       curve: Curves.easeOutCubic,
///     );
///   },
/// )
/// ```
///
/// It should be rendered together with the page content it controls (e.g.
/// stacked via a `Stack`) rather than loaded in separately, so it never
/// appears to "pop in" after the page underneath it.
class HydrateBottomNavBar extends StatelessWidget {
  const HydrateBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onItemSelected,
    this.destinations = const [
      HydrateNavDestination(
        icon: Icons.home_outlined,
        selectedIcon: Icons.home_rounded,
        label: 'Home',
      ),
      HydrateNavDestination(
        icon: Icons.alarm_outlined,
        selectedIcon: Icons.alarm_rounded,
        label: 'Alarms',
      ),
      HydrateNavDestination(
        icon: Icons.person_outline_rounded,
        selectedIcon: Icons.person_rounded,
        label: 'Profile',
      ),
    ],
  });

  final int currentIndex;
  final ValueChanged<int> onItemSelected;
  final List<HydrateNavDestination> destinations;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SafeArea(
      minimum: const EdgeInsets.only(bottom: 12, left: 20, right: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: colorScheme.surface.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: colorScheme.onSurface.withValues(alpha: 0.08),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.18),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (var i = 0; i < destinations.length; i++)
                  _NavItem(
                    destination: destinations[i],
                    selected: currentIndex == i,
                    onTap: () => onItemSelected(i),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final HydrateNavDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final activeColor = colorScheme.primary;
    final inactiveColor = colorScheme.onSurface.withValues(alpha: 0.55);

    return Expanded(
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          splashColor: colorScheme.primary.withValues(alpha: 0.12),
          highlightColor: colorScheme.primary.withValues(alpha: 0.06),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: selected
                  ? colorScheme.primary.withValues(alpha: 0.14)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) => ScaleTransition(
                    scale: animation,
                    child: child,
                  ),
                  child: Icon(
                    selected ? destination.selectedIcon : destination.icon,
                    key: ValueKey(selected),
                    color: selected ? activeColor : inactiveColor,
                    size: 24,
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  child: selected
                      ? Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(
                            destination.label,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: activeColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}