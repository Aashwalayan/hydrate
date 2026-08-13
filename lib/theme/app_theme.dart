import 'package:flutter/material.dart';

class AppTheme {
  static const Color _lightPrimary = Color(0xFF1D77FF);
  static const Color _lightSecondary = Color(0xFF79C8FF);
  static const Color _lightSurface = Color(0xFFF7FBFF);
  static const Color _darkPrimary = Color(0xFF79B8FF);
  static const Color _darkSecondary = Color(0xFF2B91FF);
  static const Color _darkSurface = Color(0xFF0E1726);

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _lightPrimary,
      brightness: Brightness.light,
      primary: _lightPrimary,
      secondary: _lightSecondary,
      surface: _lightSurface,
    );

    return _buildTheme(colorScheme);
  }

  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _darkPrimary,
      brightness: Brightness.dark,
      primary: _darkPrimary,
      secondary: _darkSecondary,
      surface: _darkSurface,
    );

    return _buildTheme(colorScheme);
  }

  static ThemeData _buildTheme(ColorScheme colorScheme) {
    final activeTextTheme = colorScheme.brightness == Brightness.dark
        ? Typography.material2021().white
        : Typography.material2021().black;
    final textTheme = activeTextTheme.copyWith(
      headlineLarge: activeTextTheme.headlineLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
      ),
      headlineSmall: activeTextTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      titleLarge: activeTextTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: activeTextTheme.bodyLarge?.copyWith(height: 1.4),
      bodyMedium: activeTextTheme.bodyMedium?.copyWith(height: 1.35),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: textTheme,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.brightness == Brightness.dark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colorScheme.error, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          minimumSize: const Size.fromHeight(58),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: colorScheme.brightness == Brightness.dark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.88),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
    );
  }
}
