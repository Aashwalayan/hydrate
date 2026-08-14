import 'package:flutter/material.dart';
import 'theme_controller.dart';

class ThemeControllerProvider
    extends InheritedNotifier<ThemeController> {
  const ThemeControllerProvider({
    super.key,
    required ThemeController controller,
    required super.child,
  }) : super(notifier: controller);

  static ThemeController of(BuildContext context) {
    final provider = context
        .dependOnInheritedWidgetOfExactType<ThemeControllerProvider>();

    assert(
      provider != null,
      'ThemeControllerProvider not found in widget tree.',
    );

    return provider!.notifier!;
  }
}