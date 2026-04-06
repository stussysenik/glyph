import 'package:flutter/material.dart';

/// iA Writer polish features: corner bracket selection borders, toolbar auto-hide,
/// and reduced motion support.
class IaWriterPolish {
  /// Corner bracket selection borders for a more refined selection experience.
  static Widget selectionBorder({
    required Widget child,
    required bool isSelected,
  }) {
    if (!isSelected) return child;

    return Stack(
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
        Positioned(
          top: -4,
          left: -4,
          right: -4,
          bottom: -4,
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white.withOpacity(0.5),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Auto-hide toolbar after 3 seconds of inactivity.
  static Widget autoHideToolbar({
    required Widget child,
    required bool isVisible,
    required VoidCallback onShow,
  }) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: isVisible ? 1.0 : 0.0,
      child: IgnorePointer(
        ignoring: !isVisible,
        child: child,
      ),
    );
  }

  /// Reduced motion support - use simpler animations when reduced motion is enabled.
  static bool get isReducedMotion {
    return SemanticsBinding.instance.accessibilityFeatures.reducedMotion;
  }

  /// Get animation duration based on reduced motion setting.
  static Duration getAnimationDuration(Duration normalDuration) {
    return isReducedMotion ? Duration.zero : normalDuration;
  }

  /// Get animation curve based on reduced motion setting.
  static Curve getAnimationCurve(Curve normalCurve) {
    return isReducedMotion ? Curves.linear : normalCurve;
  }

  /// Apply reduced motion to a widget.
  static Widget withReducedMotion({
    required Widget child,
    required Duration duration,
    required Curve curve,
  }) {
    return AnimatedSwitcher(
      duration: isReducedMotion ? Duration.zero : duration,
      switchInCurve: isReducedMotion ? Curves.linear : curve,
      switchOutCurve: isReducedMotion ? Curves.linear : curve,
      child: child,
    );
  }
}
