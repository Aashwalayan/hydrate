import 'package:flutter/material.dart';

import 'hydrate_theme.dart';

class ThemeController extends ChangeNotifier {
  ThemeController({
    ThemeMode themeMode = ThemeMode.system,
    HydrateTheme hydrateTheme = HydrateTheme.calm,
  })  : _themeMode = themeMode,
        _hydrateTheme = hydrateTheme;

  ThemeMode _themeMode;
  HydrateTheme _hydrateTheme;

  ThemeMode get themeMode => _themeMode;

  HydrateTheme get hydrateTheme => _hydrateTheme;

  void setThemeMode(ThemeMode mode) {
    if (_themeMode == mode) {
      return;
    }

    _themeMode = mode;
    notifyListeners();
  }

  void setHydrateTheme(HydrateTheme theme) {
    if (_hydrateTheme == theme) {
      return;
    }

    _hydrateTheme = theme;
    notifyListeners();
  }

  void setSettings({
    required ThemeMode themeMode,
    required HydrateTheme hydrateTheme,
  }) {
    var changed = false;

    if (_themeMode != themeMode) {
      _themeMode = themeMode;
      changed = true;
    }

    if (_hydrateTheme != hydrateTheme) {
      _hydrateTheme = hydrateTheme;
      changed = true;
    }

    if (changed) {
      notifyListeners();
    }
  }
}