import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Accessibility utilities for screen reader announcements, accessible widgets,
/// and gesture support.
class AccessibilityUtils {
  /// Announce text to screen reader with optional hint.
  static void announceToScreenReader(String text, {String? hint}) {
    SemanticsService.announce(text, hint: hint);
  }

  /// Announce success to screen reader.
  static void announceSuccess(String text) {
    announceToScreenReader(text, hint: 'Success: $text');
  }

  /// Announce error to screen reader.
  static void announceError(String text) {
    announceToScreenReader(text, hint: 'Error: $text');
  }

  /// Create an accessible button with proper semantics and labels.
  static Widget accessibleButton({
    required VoidCallback onPressed,
    required String label,
    required String hint,
    required Widget child,
    bool isDisabled = false,
  }) {
    return Semantics(
      button: true,
      label: label,
      hint: hint,
      enabled: !isDisabled,
      child: GestureDetector(
        onTap: isDisabled ? null : onPressed,
        child: child,
      ),
    );
  }

  /// Create an accessible text field with proper semantics.
  static Widget accessibleTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required FocusNode focusNode,
    required ValueChanged<String> onChanged,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: '',
        ),
        style: const TextStyle(fontSize: 16),
      ),
    );
  }

  /// Create an accessible slider with proper semantics.
  static Widget accessibleSlider({
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
    required String label,
    required String hint,
  }) {
    return Semantics(
      slider: true,
      label: label,
      value: value.toString(),
      min: min,
      max: max,
      child: Slider(
        value: value,
        min: min,
        max: max,
        onChanged: onChanged,
        activeColor: Colors.white,
        inactiveColor: Colors.white.withOpacity(0.3),
      ),
    );
  }

  /// Create an accessible color button with proper semantics.
  static Widget accessibleColorButton({
    required Color color,
    required String label,
    required String hint,
    required bool isSelected,
    required VoidCallback onPressed,
  }) {
    return Semantics(
      button: true,
      label: label,
      hint: hint,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected
                  ? Colors.white
                  : Colors.transparent,
              width: isSelected ? 2.5 : 1.5,
            ),
          ),
          child: isSelected
              ? Icon(
                  Icons.check,
                  size: 18,
                  color: color.computeLuminance() > 0.5
                      ? Colors.black
                      : Colors.white,
                )
              : null,
        ),
      ),
    );
  }

  /// Handle keyboard shortcuts for accessibility.
  static void registerKeyboardShortcuts({
    required VoidCallback onUndo,
    required VoidCallback onRedo,
    required VoidCallback onShake,
  }) {
    HardwareKeyboard.instance.addHandler((RawKeyEvent event) {
      if (event.isMetaPressed && event.physicalKey == PhysicalKeyboardKey.keyZ &&
          !event.isShiftPressed && event is KeyDownEvent) {
        onUndo();
        return KeyEventResult.handled;
      }

      if (event.isMetaPressed && event.physicalKey == PhysicalKeyboardKey.keyZ &&
          event.isShiftPressed && event is KeyDownEvent) {
        onRedo();
        return KeyEventResult.handled;
      }

      return KeyEventResult.ignored;
    });
  }

  /// Create an accessible list item with proper semantics.
  static Widget accessibleListItem({
    required String label,
    required String hint,
    required VoidCallback onPressed,
    required Widget child,
  }) {
    return Semantics(
      button: true,
      label: label,
      hint: hint,
      child: GestureDetector(
        onTap: onPressed,
        child: child,
      ),
    );
  }

  /// Simulate shake-to-undo gesture.
  static Future<void> simulateShakeGesture({
    required VoidCallback onShake,
  }) async {
    // In a real implementation, this would use device sensors
    // For now, we'll just simulate the action
    await Future.delayed(const Duration(milliseconds: 300));
    onShake();
  }
}
```
```</think>
<think></think>
Now I need to create the gesture handler file:
