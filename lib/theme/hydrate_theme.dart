import 'package:flutter/material.dart';

enum HydrateTheme {
  calm,
  ocean,
  mist,
  mint,
  lavender,
  sunset,
  berry,
  midnight,
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

  static const mint = HydrateThemeData(
    primary: Color(0xFF4DBD9A),
    secondary: Color(0xFF82D9B8),
    darkPrimary: Color(0xFF5ED6AD),
    darkSecondary: Color(0xFF83E3BE),
    name: 'Mint',
    description: 'Fresh green & teal',
  );

  static const lavender = HydrateThemeData(
    primary: Color(0xFF9B7FEA),
    secondary: Color(0xFFD18BDA),
    darkPrimary: Color(0xFFB29AFF),
    darkSecondary: Color(0xFFE09BE8),
    name: 'Lavender',
    description: 'Soft purple & pink',
  );

  static const sunset = HydrateThemeData(
    primary: Color(0xFFFF8A65),
    secondary: Color(0xFFFFB74D),
    darkPrimary: Color(0xFFFF9B78),
    darkSecondary: Color(0xFFFFC166),
    name: 'Sunset',
    description: 'Warm orange & coral',
  );

  static const berry = HydrateThemeData(
    primary: Color(0xFFE56B9F),
    secondary: Color(0xFFA875D6),
    darkPrimary: Color(0xFFF080B0),
    darkSecondary: Color(0xFFB98AE8),
    name: 'Berry',
    description: 'Pink & vibrant purple',
  );

  static const midnight = HydrateThemeData(
    primary: Color(0xFF536DFE),
    secondary: Color(0xFF26C6DA),
    darkPrimary: Color(0xFF7186FF),
    darkSecondary: Color(0xFF45D7E8),
    name: 'Midnight',
    description: 'Deep indigo & cyan',
  );

  static HydrateThemeData get(HydrateTheme theme) {
    switch (theme) {
      case HydrateTheme.calm:
        return calm;
      case HydrateTheme.ocean:
        return ocean;
      case HydrateTheme.mist:
        return mist;
      case HydrateTheme.mint:
        return mint;
      case HydrateTheme.lavender:
        return lavender;
      case HydrateTheme.sunset:
        return sunset;
      case HydrateTheme.berry:
        return berry;
      case HydrateTheme.midnight:
        return midnight;
    }
  }
}