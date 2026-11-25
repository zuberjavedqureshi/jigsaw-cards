import 'package:material_ui/material_ui.dart';

/// Provisional storybook palette (no final art direction is approved).
abstract final class Storybook {
  static const ink = Color(0xFF3B2A1A);
  static const parchment = Color(0xFFF7EBCB);
  static const gold = Color(0xFFFFC94D);
  static const wood = Color(0xFF6B4A2B);
  static const skyTop = Color(0xFF2E3A6E);
  static const skyBottom = Color(0xFF7C5E9E);

  static ThemeData theme() => ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: wood, surface: parchment),
    fontFamily: 'serif',
  );

  static const background = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [skyTop, skyBottom],
    ),
  );
}
