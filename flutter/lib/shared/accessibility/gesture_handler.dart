import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';

/// Handles rotation gestures and shake-to-undo functionality
class GestureHandler {
  final BuildContext context;
  final VoidCallback onDoubleTap;
  final VoidCallback onLongPress;
  final VoidCallback onRotation;
  final VoidCallback onShake;

  GestureHandler({
    required this.context,
    required this.onDoubleTap,
    required this.onLongPress,
    required this.onRotation,
    required this.onShake,
  });

  /// Handle rotation gestures
  void handleRotationGesture(DragUpdateDetails details) {
    final rotationDelta = details.delta.dx * 0.5; // Scale for natural feel
    onRotation();
  }

  /// Handle shake-to-undo gesture
  void handleShakeGesture() {
    onShake();
  }

  /// Register shake detection
  void registerShakeDetection() {
    // In a real implementation, this would use device sensors
    // For now, we'll simulate the shake gesture
    Timer.periodic(const Duration(seconds: 5), (timer) {
      // Simulate shake every 5 seconds for testing
      handleShakeGesture();
    });
  }

  /// Register rotation gesture detector
  GestureDetector createRotationDetector({
    required Widget child,
  }) {
    return GestureDetector(
      onDoubleTap: () => onDoubleTap(),
      onLongPress: () => onLongPress(),
      onPanUpdate: (details) => handleRotationGesture(details),
      child: child,
    );
  }
}
