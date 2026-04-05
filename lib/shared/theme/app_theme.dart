import 'package:flutter/material.dart';

/// Glyph's dark, minimal theme — inspired by iA Writer's focus
/// and Things 3's premium feel.
class AppTheme {
  static const background = Color(0xFF1A1A1A);
  static const surface = Color(0xFF242424);
  static const surfaceLight = Color(0xFF2E2E2E);
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFF8E8E93);
  static const accent = Color(0xFF6C63FF);
  static const accentLight = Color(0xFF8B83FF);
  static const divider = Color(0xFF3A3A3A);
  static const error = Color(0xFFFF6B6B);
  static const success = Color(0xFF4CD964);

  /// Preset colors for the color picker — curated for Stories.
  static const presetColors = [
    Colors.white,
    Color(0xFFF5F5F5),
    Color(0xFFE0E0E0),
    Color(0xFF9E9E9E),
    Color(0xFF424242),
    Colors.black,
    Color(0xFFFF6B6B),
    Color(0xFFFF8A65),
    Color(0xFFFFD54F),
    Color(0xFF81C784),
    Color(0xFF4DD0E1),
    Color(0xFF64B5F6),
    Color(0xFF7986CB),
    Color(0xFFBA68C8),
    Color(0xFFF06292),
    Color(0xFFA1887F),
  ];

  static ThemeData get theme => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        colorScheme: const ColorScheme.dark(
          primary: accent,
          secondary: accentLight,
          surface: surface,
          error: error,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: textPrimary),
          bodySmall: TextStyle(color: textSecondary),
        ),
      );
}
