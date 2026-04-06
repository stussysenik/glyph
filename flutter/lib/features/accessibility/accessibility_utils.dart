import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Accessibility utilities for the Instagram Story Builder app.
/// Provides screen reader support, focus management, and haptic feedback.
class AccessibilityUtils {
  /// Announce text to screen reader with optional hints.
  static void announceToScreenReader(String message, {String? hint}) {
    SemanticsService.announce(message, TextDirection.ltr);
    if (hint != null) {
      SemanticsService.announce(hint, TextDirection.ltr);
    }
  }

  /// Announce a success message with haptic feedback.
  static void announceSuccess(String message) {
    HapticFeedback.lightImpact();
    announceToScreenReader(message, hint: 'Success');
  }

  /// Announce an error message with haptic feedback.
  static void announceError(String message) {
    HapticFeedback.heavyImpact();
    announceToScreenReader(message, hint: 'Error');
  }

  /// Announce a warning message with haptic feedback.
  static void announceWarning(String message) {
    HapticFeedback.mediumImpact();
    announceToScreenReader(message, hint: 'Warning');
  }

  /// Announce a navigation action with haptic feedback.
  static void announceNavigation(String message) {
    HapticFeedback.selectionClick();
    announceToScreenReader(message, hint: 'Navigation');
  }

  /// Create an accessible button with proper semantics and focus management.
  static Widget accessibleButton({
    required VoidCallback onPressed,
    required String label,
    required String hint,
    required Widget child,
    bool isPrimary = false,
    bool enabled = true,
    FocusNode? focusNode,
    VoidCallback? onLongPress,
  }) {
    return Semantics(
      button: true,
      label: label,
      hint: hint,
      child: Focus(
        focusNode: focusNode,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.select) {
              onPressed();
              return KeyEventResult.handled;
            }
            if (onLongPress != null &&
                event.logicalKey == LogicalKeyboardKey.enter) {
              onLongPress();
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: GestureDetector(
          onTap: enabled ? onPressed : null,
          onLongPress: enabled ? onLongPress : null,
          onTapDown: (_) => HapticFeedback.selectionClick(),
          child: Opacity(
            opacity: enabled ? 1.0 : 0.5,
            child: child,
          ),
        ),
      ),
    );
  }

  /// Create an accessible text field with proper semantics and focus management.
  static Widget accessibleTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required FocusNode focusNode,
    required ValueChanged<String> onChanged,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    bool enabled = true,
    String? errorText,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        enabled: enabled,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          errorText: errorText,
          border: const OutlineInputBorder(),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.blue),
          ),
        ),
        onTap: () => HapticFeedback.selectionClick(),
        onSubmitted: (_) => HapticFeedback.lightImpact(),
      ),
    );
  }

  /// Create an accessible slider with proper semantics and focus management.
  static Widget accessibleSlider({
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
    required String label,
    required String hint,
    FocusNode? focusNode,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      child: Focus(
        focusNode: focusNode,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
              final newValue = value - 1;
              if (newValue >= min) {
                onChanged(newValue);
                HapticFeedback.lightImpact();
              }
              return KeyEventResult.handled;
            }
            if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
              final newValue = value + 1;
              if (newValue <= max) {
                onChanged(newValue);
                HapticFeedback.lightImpact();
              }
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: Slider(
          value: value,
          min: min,
          max: max,
          onChanged: onChanged,
          activeColor: Colors.blue,
          inactiveColor: Colors.grey,
        ),
      ),
    );
  }

  /// Create an accessible color picker with proper semantics.
  static Widget accessibleColorButton({
    required Color color,
    required String label,
    required String hint,
    required VoidCallback onPressed,
    bool isSelected = false,
    FocusNode? focusNode,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      child: Focus(
        focusNode: focusNode,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.select) {
              onPressed();
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: GestureDetector(
          onTap: () {
            onPressed();
            HapticFeedback.selectionClick();
          },
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.blue : Colors.transparent,
                width: 3,
              ),
            ),
            child: isSelected
                ? Icon(
                    Icons.check,
                    color: color.computeLuminance() > 0.5
                        ? Colors.black
                        : Colors.white,
                    size: 24,
                  )
                : null,
          ),
        ),
      ),
    );
  }

  /// Create an accessible list item with proper semantics.
  static Widget accessibleListItem({
    required String label,
    required String hint,
    required VoidCallback onPressed,
    required Widget child,
    FocusNode? focusNode,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      child: Focus(
        focusNode: focusNode,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.select) {
              onPressed();
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: GestureDetector(
          onTap: () {
            onPressed();
            HapticFeedback.selectionClick();
          },
          child: child,
        ),
      ),
    );
  }

  /// Create an accessible toggle switch with proper semantics.
  static Widget accessibleToggle({
    required bool value,
    required String label,
    required String hint,
    required ValueChanged<bool> onChanged,
    FocusNode? focusNode,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      child: Focus(
        focusNode: focusNode,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.select) {
              onChanged(!value);
              HapticFeedback.selectionClick();
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.blue,
        ),
      ),
    );
  }

  /// Create an accessible dropdown with proper semantics.
  static Widget accessibleDropdown<T>({
    required T value,
    required List<T> items,
    required String label,
    required String hint,
    required ValueChanged<T> onChanged,
    required String Function(T) displayBuilder,
    FocusNode? focusNode,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      child: Focus(
        focusNode: focusNode,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.select) {
              // Open dropdown
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: DropdownButton<T>(
          value: value,
          items: items
              .map((item) => DropdownMenuItem<T>(
                    value: item,
                    child: Text(displayBuilder(item)),
                  ))
              .toList(),
          onChanged: onChanged,
          isExpanded: true,
          underline: Container(
            height: 2,
            color: Colors.blue,
          ),
        ),
      ),
    );
  }

  /// Announce a progress update.
  static void announceProgress(String message, {int? progress, int? total}) {
    final progressText = progress != null && total != null
        ? '($progress of $total)'
        : '';
    announceToScreenReader('$message $progressText');
  }

  /// Announce a loading state.
  static void announceLoading(String message) {
    announceToScreenReader(message, hint: 'Loading');
  }

  /// Announce completion.
  static void announceComplete(String message) {
    HapticFeedback.mediumImpact();
    announceToScreenReader(message, hint: 'Complete');
  }
}

/// Accessibility provider for managing accessibility settings.
class AccessibilityProvider extends StateNotifier<bool> {
  AccessibilityProvider() : super(false);

  /// Check if screen reader is enabled.
  static Future<bool> isScreenReaderEnabled() async {
    try {
      final result = await SemanticsService.isScreenReaderEnabled();
      return result;
    } catch (e) {
      return false;
    }
  }

  /// Toggle accessibility mode.
  void toggleAccessibility() {
    state = !state;
  }

  /// Enable accessibility mode.
  void enableAccessibility() {
    state = true;
  }

  /// Disable accessibility mode.
  void disableAccessibility() {
    state = false;
  }
}

final accessibilityProvider = StateNotifierProvider<AccessibilityProvider, bool>(
  (ref) => AccessibilityProvider(),
);
