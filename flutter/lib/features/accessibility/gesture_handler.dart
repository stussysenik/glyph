import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Gesture handler system for managing touch interactions and haptic feedback.
/// Provides double-tap, long-press, swipe, and pinch gestures with accessibility support.
class GestureHandler {
  final BuildContext context;
  final Ref ref;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;
  final VoidCallback? onSwipeUp;
  final VoidCallback? onSwipeDown;
  final ValueChanged<double>? onPinch;
  final ValueChanged<double>? onRotate;
  final ValueChanged<Offset>? onDrag;

  GestureHandler({
    required this.context,
    required this.ref,
    this.onDoubleTap,
    this.onLongPress,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.onSwipeUp,
    this.onSwipeDown,
    this.onPinch,
    this.onRotate,
    this.onDrag,
  });

  /// Create a gesture detector with multiple gesture support.
  Widget createGestureDetector({
    required Widget child,
    bool enableDoubleTap = true,
    bool enableLongPress = true,
    bool enableSwipe = true,
    bool enablePinch = false,
    bool enableRotate = false,
    bool enableDrag = false,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _handleTap(),
      onDoubleTap: enableDoubleTap ? _handleDoubleTap : null,
      onLongPress: enableLongPress ? _handleLongPress : null,
      onHorizontalDragStart: enableDrag ? _handleDragStart : null,
      onHorizontalDragUpdate: enableDrag ? _handleDragUpdate : null,
      onHorizontalDragEnd: enableDrag ? _handleDragEnd : null,
      onVerticalDragStart: enableDrag ? _handleDragStart : null,
      onVerticalDragUpdate: enableDrag ? _handleDragUpdate : null,
      onVerticalDragEnd: enableDrag ? _handleDragEnd : null,
      onScaleStart: enablePinch || enableRotate ? _handleScaleStart : null,
      onScaleUpdate: enablePinch || enableRotate ? _handleScaleUpdate : null,
      onScaleEnd: enablePinch || enableRotate ? _handleScaleEnd : null,
      child: child,
    );
  }

  /// Handle single tap with haptic feedback.
  void _handleTap() {
    HapticFeedback.lightImpact();
    _announceAction('Tapped');
  }

  /// Handle double tap with haptic feedback.
  void _handleDoubleTap() {
    HapticFeedback.mediumImpact();
    _announceAction('Double tapped');
    onDoubleTap?.call();
  }

  /// Handle long press with haptic feedback.
  void _handleLongPress() {
    HapticFeedback.heavyImpact();
    _announceAction('Long pressed');
    onLongPress?.call();
  }

  /// Handle drag start.
  void _handleDragStart(DragStartDetails details) {
    _announceAction('Drag started');
  }

  /// Handle drag update.
  void _handleDragUpdate(DragUpdateDetails details) {
    onDrag?.call(details.localPosition);
  }

  /// Handle drag end.
  void _handleDragEnd(DragEndDetails details) {
    _announceAction('Drag ended');
  }

  /// Handle scale start (for pinch/rotate).
  void _handleScaleStart(ScaleStartDetails details) {
    _announceAction('Scale started');
  }

  /// Handle scale update (for pinch/rotate).
  void _handleScaleUpdate(ScaleUpdateDetails details) {
    if (onPinch != null && details.scale != 1.0) {
      onPinch!(details.scale);
      if (details.scale > 1.0) {
        HapticFeedback.lightImpact();
      } else {
        HapticFeedback.mediumImpact();
      }
    }

    if (onRotate != null && details.rotation != 0.0) {
      onRotate!(details.rotation);
      HapticFeedback.selectionClick();
    }
  }

  /// Handle scale end.
  void _handleScaleEnd(ScaleEndDetails details) {
    _announceAction('Scale ended');
  }

  /// Announce action to screen reader.
  void _announceAction(String action) {
    if (ref.read(accessibilityProvider)) {
      AccessibilityUtils.announceToScreenReader(action);
    }
  }

  /// Create a gesture recognizer for custom gesture handling.
  static GestureRecognizer createGestureRecognizer({
    VoidCallback? onTap,
    VoidCallback? onDoubleTap,
    VoidCallback? onLongPress,
    VoidCallback? onHorizontalDragStart,
    ValueChanged<DragUpdateDetails>? onHorizontalDragUpdate,
    VoidCallback? onHorizontalDragEnd,
    VoidCallback? onVerticalDragStart,
    ValueChanged<DragUpdateDetails>? onVerticalDragUpdate,
    VoidCallback? onVerticalDragEnd,
    VoidCallback? onScaleStart,
    ValueChanged<ScaleUpdateDetails>? onScaleUpdate,
    VoidCallback? onScaleEnd,
  }) {
    return _CustomGestureRecognizer(
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      onLongPress: onLongPress,
      onHorizontalDragStart: onHorizontalDragStart,
      onHorizontalDragUpdate: onHorizontalDragUpdate,
      onHorizontalDragEnd: onHorizontalDragEnd,
      onVerticalDragStart: onVerticalDragStart,
      onVerticalDragUpdate: onVerticalDragUpdate,
      onVerticalDragEnd: onVerticalDragEnd,
      onScaleStart: onScaleStart,
      onScaleUpdate: onScaleUpdate,
      onScaleEnd: onScaleEnd,
    );
  }
}

/// Custom gesture recognizer for handling multiple gesture types.
class _CustomGestureRecognizer extends OneSequenceGestureRecognizer {
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onHorizontalDragStart;
  final ValueChanged<DragUpdateDetails>? onHorizontalDragUpdate;
  final VoidCallback? onHorizontalDragEnd;
  final VoidCallback? onVerticalDragStart;
  final ValueChanged<DragUpdateDetails>? onVerticalDragUpdate;
  final VoidCallback? onVerticalDragEnd;
  final VoidCallback? onScaleStart;
  final ValueChanged<ScaleUpdateDetails>? onScaleUpdate;
  final VoidCallback? onScaleEnd;

  _CustomGestureRecognizer({
    this.onTap,
    this.onDoubleTap,
    this.onLongPress,
    this.onHorizontalDragStart,
    this.onHorizontalDragUpdate,
    this.onHorizontalDragEnd,
    this.onVerticalDragStart,
    this.onVerticalDragUpdate,
    this.onVerticalDragEnd,
    this.onScaleStart,
    this.onScaleUpdate,
    this.onScaleEnd,
  });

  @override
  void addPointer(PointerDownEvent event) {
    startTrackingPointer(event.pointer);
    resolve(GestureDisposition.accepted);
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event is PointerDownEvent) {
      _handlePointerDown(event);
    } else if (event is PointerMoveEvent) {
      _handlePointerMove(event);
    } else if (event is PointerUpEvent) {
      _handlePointerUp(event);
    } else if (event is PointerCancelEvent) {
      _handlePointerCancel(event);
    }
  }

  void _handlePointerDown(PointerDownEvent event) {
    // Handle tap and double tap logic
    if (onTap != null || onDoubleTap != null) {
      // Simple tap handling
      if (onTap != null) {
        onTap!();
      }

      // Double tap logic would be more complex with timing
      if (onDoubleTap != null) {
        onDoubleTap!();
      }
    }

    if (onLongPress != null) {
      // Long press logic would need a timer
    }
  }

  void _handlePointerMove(PointerEvent event) {
    if (onHorizontalDragUpdate != null && event is PointerMoveEvent) {
      onHorizontalDragUpdate!(DragUpdateDetails(
        globalPosition: event.position,
        delta: event.delta,
        primaryDelta: event.delta.dx,
        localPosition: event.position,
        kind: PointerDeviceKind.touch,
      ));
    }

    if (onVerticalDragUpdate != null && event is PointerMoveEvent) {
      onVerticalDragUpdate!(DragUpdateDetails(
        globalPosition: event.position,
        delta: event.delta,
        primaryDelta: event.delta.dy,
        localPosition: event.position,
        kind: PointerDeviceKind.touch,
      ));
    }

    if (onScaleUpdate != null && event is PointerMoveEvent) {
      // Scale update logic would need multiple pointers
    }
  }

  void _handlePointerUp(PointerUpEvent event) {
    if (onHorizontalDragEnd != null) {
      onHorizontalDragEnd!();
    }

    if (onVerticalDragEnd != null) {
      onVerticalDragEnd!();
    }

    if (onScaleEnd != null) {
      onScaleEnd!();
    }
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    if (onHorizontalDragEnd != null) {
      onHorizontalDragEnd!();
    }

    if (onVerticalDragEnd != null) {
      onVerticalDragEnd!();
    }

    if (onScaleEnd != null) {
      onScaleEnd!();
    }
  }

  @override
  String get debugDescription => 'CustomGestureRecognizer';

  @override
  void acceptGesture(int pointer) {}

  @override
  void didStopTrackingLastPointer(int pointer) {}

  @override
  void handlePrimaryPointer(PointerEvent event) {}
}

/// Gesture configuration for different interaction modes.
class GestureConfig {
  static const double doubleTapTimeout = 300.0; // milliseconds
  static const double longPressTimeout = 500.0; // milliseconds
  static const double swipeSensitivity = 50.0; // pixels
  static const double pinchSensitivity = 0.1; // scale factor
  static const double rotateSensitivity = 0.1; // radians

  /// Get default gesture configuration.
  static Map<String, dynamic> getDefaultConfig() {
    return {
      'doubleTapTimeout': doubleTapTimeout,
      'longPressTimeout': longPressTimeout,
      'swipeSensitivity': swipeSensitivity,
      'pinchSensitivity': pinchSensitivity,
      'rotateSensitivity': rotateSensitivity,
    };
  }

  /// Get accessibility optimized gesture configuration.
  static Map<String, dynamic> getAccessibilityConfig() {
    return {
      'doubleTapTimeout': doubleTapTimeout * 1.5,
      'longPressTimeout': longPressTimeout * 1.5,
      'swipeSensitivity': swipeSensitivity * 0.5,
      'pinchSensitivity': pinchSensitivity * 0.5,
      'rotateSensitivity': rotateSensitivity * 0.5,
    };
  }
}

/// Gesture state management for tracking gesture interactions.
class GestureState {
  final String gestureType;
  final DateTime startTime;
  final Offset startPosition;
  final double initialScale;
  final double initialRotation;

  GestureState({
    required this.gestureType,
    required this.startTime,
    required this.startPosition,
    this.initialScale = 1.0,
    this.initialRotation = 0.0,
  });

  /// Check if gesture is still active (within timeout).
  bool isActive(Duration timeout) {
    return DateTime.now().difference(startTime) < timeout;
  }

  /// Get gesture duration.
  Duration get duration {
    return DateTime.now().difference(startTime);
  }
}

/// Gesture provider for managing gesture state and configuration.
class GestureProvider extends StateNotifier<GestureState?> {
  GestureProvider() : super(null);

  /// Start a new gesture.
  void startGesture({
    required String gestureType,
    required Offset position,
    double initialScale = 1.0,
    double initialRotation = 0.0,
  }) {
    state = GestureState(
      gestureType: gestureType,
      startTime: DateTime.now(),
      startPosition: position,
      initialScale: initialScale,
      initialRotation: initialRotation,
    );
  }

  /// End current gesture.
  void endGesture() {
    state = null;
  }

  /// Update gesture state.
  void updateGesture(Offset position) {
    if (state != null) {
      // Update position or other state as needed
    }
  }

  /// Check if specific gesture is active.
  bool isGestureActive(String gestureType) {
    return state?.gestureType == gestureType;
  }
}

final gestureProvider = StateNotifierProvider<GestureProvider, GestureState?>(
  (ref) => GestureProvider(),
);
