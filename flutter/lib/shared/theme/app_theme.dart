import 'package:flutter/material.dart';

/// Glyph's dark, minimal theme — inspired by iA Writer's focus
/// and Things 3's premium feel.
/// Enhanced with accessibility features for better usability.
class AppTheme {
  // Base colors (maintained for backward compatibility)
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

  // Accessibility color schemes
  static const highContrastBackground = Color(0xFF000000);
  static const highContrastSurface = Color(0xFF111111);
  static const highContrastTextPrimary = Color(0xFFFFFFFF);
  static const highContrastTextSecondary = Color(0xFFCCCCCC);
  static const highContrastAccent = Color(0xFF00FFFF);
  static const highContrastDivider = Color(0xFF555555);

  // Large text colors (improved readability)
  static const largeTextBackground = Color(0xFF1F1F1F);
  static const largeTextSurface = Color(0xFF2D2D2D);
  static const largeTextPrimary = Color(0xFFFFFFFF);
  static const largeTextSecondary = Color(0xFFAAAAAA);
  static const largeTextAccent = Color(0xFF7B68EE);
  static const largeTextDivider = Color(0xFF444444);

  // Reduced motion colors (simplified animations)
  static const reducedMotionBackground = Color(0xFF1A1A1A);
  static const reducedMotionSurface = Color(0xFF242424);
  static const reducedMotionTextPrimary = Color(0xFFFFFFFF);
  static const reducedMotionTextSecondary = Color(0xFF8E8E93);
  static const reducedMotionAccent = Color(0xFF6C63FF);
  static const reducedMotionDivider = Color(0xFF3A3A3A);

  // Accessibility color palette for color picker
  static const accessibilityColors = [
    // High contrast colors
    Color(0xFFFFFFFF), // White
    Color(0xFFFF0000), // Red
    Color(0xFF00FF00), // Green
    Color(0xFF0000FF), // Blue
    Color(0xFFFF00FF), // Magenta
    Color(0xFFFFFF00), // Yellow
    Color(0xFF00FFFF), // Cyan
    Color(0xFF000000), // Black

    // Standard colors with good contrast
    Color(0xFFF5F5F5), // Light gray
    Color(0xFFE0E0E0), // Medium light gray
    Color(0xFF9E9E9E), // Medium gray
    Color(0xFF424242), // Dark gray
    Color(0xFF6C63FF), // Purple
    Color(0xFF4CD964), // Green
    Color(0xFFFF6B6B), // Red
    Color(0xFF64B5F6), // Blue
  ];

  // Preset colors for the color picker — curated for Stories.
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

  // Accessibility theme variants
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
        // Accessibility improvements
        typography: Typography.material2018(
          black: Typography.blackCupertino.apply(
            bodyMedium: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.15,
            ),
          ),
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      );

  // High contrast theme for accessibility
  static ThemeData get highContrastTheme => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: highContrastBackground,
        colorScheme: const ColorScheme.dark(
          primary: highContrastAccent,
          secondary: highContrastAccent,
          surface: highContrastSurface,
          error: Color(0xFFFF0000),
          onSurface: highContrastTextPrimary,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: highContrastSurface,
          elevation: 0,
          centerTitle: false,
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: highContrastSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(
            color: highContrastTextPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
          bodySmall: TextStyle(
            color: highContrastTextSecondary,
            fontSize: 14,
          ),
        ),
        // Enhanced contrast for accessibility
        typography: Typography.material2018(
          black: Typography.blackCupertino.apply(
            bodyMedium: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      );

  // Large text theme for accessibility
  static ThemeData get largeTextTheme => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: largeTextBackground,
        colorScheme: const ColorScheme.dark(
          primary: largeTextAccent,
          secondary: largeTextAccent,
          surface: largeTextSurface,
          error: Color(0xFFFF6B6B),
          onSurface: largeTextPrimary,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: largeTextSurface,
          elevation: 0,
          centerTitle: false,
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: largeTextSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(
            color: largeTextPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.15,
          ),
          bodySmall: TextStyle(
            color: largeTextSecondary,
            fontSize: 16,
          ),
        ),
        // Larger text for better readability
        typography: Typography.material2018(
          black: Typography.blackCupertino.apply(
            bodyMedium: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      );

  // Reduced motion theme for accessibility
  static ThemeData get reducedMotionTheme => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: reducedMotionBackground,
        colorScheme: const ColorScheme.dark(
          primary: reducedMotionAccent,
          secondary: reducedMotionAccent,
          surface: reducedMotionSurface,
          error: Color(0xFFFF6B6B),
          onSurface: reducedMotionTextPrimary,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: reducedMotionSurface,
          elevation: 0,
          centerTitle: false,
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: reducedMotionSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(
            color: reducedMotionTextPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
          bodySmall: TextStyle(
            color: reducedMotionTextSecondary,
            fontSize: 14,
          ),
        ),
        // Reduced motion for accessibility
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.iOS: FadeUpwardsPageTransitionsBuilder(),
          },
        ),
        typography: Typography.material2018(
          black: Typography.blackCupertino.apply(
            bodyMedium: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.15,
            ),
          ),
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      );

  // Get theme based on accessibility settings
  static ThemeData getTheme({
    bool highContrast = false,
    bool largeText = false,
    bool reducedMotion = false,
  }) {
    if (highContrast) {
      return highContrastTheme;
    } else if (largeText) {
      return largeTextTheme;
    } else if (reducedMotion) {
      return reducedMotionTheme;
    }
    return theme;
  }

  // Get color based on accessibility settings
  static Color getTextColor({
    bool highContrast = false,
    bool largeText = false,
  }) {
    if (highContrast) {
      return highContrastTextPrimary;
    } else if (largeText) {
      return largeTextPrimary;
    }
    return textPrimary;
  }

  // Get surface color based on accessibility settings
  static Color getSurfaceColor({
    bool highContrast = false,
    bool largeText = false,
  }) {
    if (highContrast) {
      return highContrastSurface;
    } else if (largeText) {
      return largeTextSurface;
    }
    return surface;
  }

  // Get accent color based on accessibility settings
  static Color getAccentColor({
    bool highContrast = false,
    bool largeText = false,
  }) {
    if (highContrast) {
      return highContrastAccent;
    } else if (largeText) {
      return largeTextAccent;
    }
    return accent;
  }

  // Get divider color based on accessibility settings
  static Color getDividerColor({
    bool highContrast = false,
    bool largeText = false,
  }) {
    if (highContrast) {
      return highContrastDivider;
    } else if (largeText) {
      return largeTextDivider;
    }
    return divider;
  }

  // Calculate contrast ratio between two colors
  static double contrastRatio(Color color1, Color color2) {
    final luminance1 = color1.computeLuminance();
    final luminance2 = color2.computeLuminance();
    final ratio = (luminance1 + 0.05) / (luminance2 + 0.05);
    return ratio > 1 ? ratio : 1 / ratio;
  }

  // Check if color combination has sufficient contrast
  static bool hasSufficientContrast(Color textColor, Color backgroundColor) {
    final ratio = contrastRatio(textColor, backgroundColor);
    // WCAG AA standard: 4.5:1 for normal text, 3:1 for large text
    return ratio >= 4.5;
  }

  // Get accessible color with sufficient contrast
  static Color getAccessibleColor(Color backgroundColor, {bool largeText = false}) {
    final requiredRatio = largeText ? 3.0 : 4.5;

    // Try primary text color first
    if (contrastRatio(textPrimary, backgroundColor) >= requiredRatio) {
      return textPrimary;
    }

    // Try secondary text color
    if (contrastRatio(textSecondary, backgroundColor) >= requiredRatio) {
      return textSecondary;
    }

    // Try high contrast colors
    if (contrastRatio(highContrastTextPrimary, backgroundColor) >= requiredRatio) {
      return highContrastTextPrimary;
    }

    // Fallback to white (highest contrast)
    return Colors.white;
  }
}
