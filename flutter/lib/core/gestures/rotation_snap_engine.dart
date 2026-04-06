import 'dart:math';

import 'package:flutter/services.dart';

/// Handles rotation snapping to cardinal angles (0°, 90°, 180°, 270°)
/// with haptic feedback and degree badge display.
class RotationSnapEngine {
  static const double _threshold = 5.0; // 5° threshold for snapping
  static const List<double> _cardinalAngles = [0.0, 90.0, 180.0, 270.0];

  /// Normalize angle to 0-360 range
  static double _normalizeAngle(double angle) {
    return (angle % 360 + 360) % 360;
  }

  /// Find the nearest cardinal angle to the given angle
  static double _findNearestCardinalAngle(double angle) {
    angle = _normalizeAngle(angle);
    double nearest = _cardinalAngles[0];
    double minDiff = double.infinity;

    for (final cardinal in _cardinalAngles) {
      final diff = (angle - cardinal).abs();
      if (diff < minDiff) {
        minDiff = diff;
        nearest = cardinal;
      }
    }

    return nearest;
  }

  /// Check if the current angle should snap to a cardinal angle
  static bool shouldSnap(double currentAngle, double targetAngle) {
    final nearest = _findNearestCardinalAngle(targetAngle);
    final diff = (targetAngle - nearest).abs();
    return diff <= _threshold;
  }

  /// Snap the angle to the nearest cardinal angle
  static double snapAngle(double angle) {
    return _findNearestCardinalAngle(angle);
  }

  /// Provide haptic feedback for rotation snap
  static void provideHapticFeedback() {
    HapticFeedback.mediumImpact();
  }

  /// Get the degree badge text for the current angle
  static String getDegreeBadge(double angle) {
    final normalized = _normalizeAngle(angle);
    return '${normalized.round()}°';
  }

  /// Check if the angle is already at a cardinal position
  static bool isAtCardinalAngle(double angle) {
    angle = _normalizeAngle(angle);
    return _cardinalAngles.contains(angle);
  }
}
