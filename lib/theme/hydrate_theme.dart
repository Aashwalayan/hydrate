import 'package:flutter/material.dart';

enum HydrateTheme {
  calm,
  ocean,
  mist,
}

class HydrateThemeData {
  const HydrateThemeData({
    required this.primary,
    required this.secondary,
    required this.darkPrimary,
    required this.darkSecondary,
    required this.name,
    required this.description,
  });

  final Color primary;
  final Color secondary;

  final Color darkPrimary;
  final Color darkSecondary;

  final String name;
  final String description;
}

class HydrateThemes {
  static const calm = HydrateThemeData(
    primary: Color(0xFF4FC3E8),
    secondary: Color(0xFF7FD8C7),
    darkPrimary: Color(0xFF5FD3F3),
    darkSecondary: Color(0xFF6FE0C9),
    name: 'Calm Water',
    description: 'Soft cyan & seafoam',
  );

  static const ocean = HydrateThemeData(
    primary: Color(0xFF5FB8E8),
    secondary: Color(0xFF69D6D0),
    darkPrimary: Color(0xFF6FC7F2),
    darkSecondary: Color(0xFF70E2DC),
    name: 'Ocean',
    description: 'Cool blue & aqua',
  );

  static const mist = HydrateThemeData(
    primary: Color(0xFF8CB8F2),
    secondary: Color(0xFFA78BFA),
    darkPrimary: Color(0xFFA6C9FF),
    darkSecondary: Color(0xFFB9A7FF),
    name: 'Mist',
    description: 'Blue & muted lavender',
  );

  static HydrateThemeData get(HydrateTheme theme) {
    switch (theme) {
      case HydrateTheme.calm:
        return calm;
      case HydrateTheme.ocean:
        return ocean;
      case HydrateTheme.mist:
        return mist;
    }
  }
}