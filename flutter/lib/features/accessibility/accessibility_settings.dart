import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_switch/flutter_switch.dart';

import '../../shared/theme/app_theme.dart';
import '../accessibility/accessibility_utils.dart';
import '../accessibility/gesture_handler.dart';

/// Accessibility settings screen for configuring accessibility features.
class AccessibilitySettingsScreen extends ConsumerStatefulWidget {
  const AccessibilitySettingsScreen({super.key});

  @override
  ConsumerState<AccessibilitySettingsScreen> createState() =>
      _AccessibilitySettingsScreenState();
}

class _AccessibilitySettingsScreenState
    extends ConsumerState<AccessibilitySettingsScreen> {
  bool _screenReaderEnabled = false;
  bool _hapticFeedback = true;
  bool _largeText = false;
  bool _highContrast = false;
  bool _reduceMotion = false;
  bool _voiceOver = false;
  bool _switchControl = false;
  bool _voiceControl = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  /// Load saved accessibility settings.
  Future<void> _loadSettings() async {
    // In a real app, this would load from storage
    final accessibilityEnabled = ref.read(accessibilityProvider);
    setState(() {
      _screenReaderEnabled = accessibilityEnabled;
      _hapticFeedback = true;
      _largeText = false;
      _highContrast = false;
      _reduceMotion = false;
      _voiceOver = false;
      _switchControl = false;
      _voiceControl = false;
    });
  }

  /// Save accessibility settings.
  Future<void> _saveSettings() async {
    ref.read(accessibilityProvider.notifier).toggleAccessibility();
    AccessibilityUtils.announceSuccess('Accessibility settings saved');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  /// Build the app bar with title and save button.
  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.surface,
      elevation: 0,
      title: const Text(
        'Accessibility Settings',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.save, color: AppTheme.accent),
          onPressed: _saveSettings,
          tooltip: 'Save settings',
        ),
      ],
    );
  }

  /// Build the main settings body.
  Widget _buildBody() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        _buildSectionTitle('General Accessibility'),
        _buildScreenReaderToggle(),
        _buildHapticFeedbackToggle(),
        _buildSectionTitle('Visual Accessibility'),
        _buildLargeTextToggle(),
        _buildHighContrastToggle(),
        _buildReduceMotionToggle(),
        _buildSectionTitle('Voice & Control'),
        _buildVoiceOverToggle(),
        _buildSwitchControlToggle(),
        _buildVoiceControlToggle(),
        _buildSectionTitle('Gesture Settings'),
        _buildGestureSensitivitySlider(),
        _buildDoubleTapTimeoutSlider(),
        _buildLongPressTimeoutSlider(),
      ],
    );
  }

  /// Build a section title.
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }

  /// Build screen reader toggle.
  Widget _buildScreenReaderToggle() {
    return _buildToggleSetting(
      label: 'Screen Reader',
      hint: 'Enable screen reader for voice feedback',
      value: _screenReaderEnabled,
      onChanged: (value) {
        setState(() => _screenReaderEnabled = value);
        if (value) {
          AccessibilityUtils.announceToScreenReader(
            'Screen reader enabled',
            hint: 'Accessibility feature',
          );
        }
      },
    );
  }

  /// Build haptic feedback toggle.
  Widget _buildHapticFeedbackToggle() {
    return _buildToggleSetting(
      label: 'Haptic Feedback',
      hint: 'Provide haptic feedback for interactions',
      value: _hapticFeedback,
      onChanged: (value) {
        setState(() => _hapticFeedback = value);
        if (value) {
          HapticFeedback.lightImpact();
        }
      },
    );
  }

  /// Build large text toggle.
  Widget _buildLargeTextToggle() {
    return _buildToggleSetting(
      label: 'Large Text',
      hint: 'Increase text size for better readability',
      value: _largeText,
      onChanged: (value) {
        setState(() => _largeText = value);
        if (value) {
          AccessibilityUtils.announceToScreenReader(
            'Large text enabled',
            hint: 'Visual accessibility',
          );
        }
      },
    );
  }

  /// Build high contrast toggle.
  Widget _buildHighContrastToggle() {
    return _buildToggleSetting(
      label: 'High Contrast',
      hint: 'Increase contrast for better visibility',
      value: _highContrast,
      onChanged: (value) {
        setState(() => _highContrast = value);
        if (value) {
          AccessibilityUtils.announceToScreenReader(
            'High contrast enabled',
            hint: 'Visual accessibility',
          );
        }
      },
    );
  }

  /// Build reduce motion toggle.
  Widget _buildReduceMotionToggle() {
    return _buildToggleSetting(
      label: 'Reduce Motion',
      hint: 'Reduce animations and motion effects',
      value: _reduceMotion,
      onChanged: (value) {
        setState(() => _reduceMotion = value);
        if (value) {
          AccessibilityUtils.announceToScreenReader(
            'Motion reduced',
            hint: 'Accessibility feature',
          );
        }
      },
    );
  }

  /// Build voice over toggle.
  Widget _buildVoiceOverToggle() {
    return _buildToggleSetting(
      label: 'VoiceOver',
      hint: 'Enable voice commands and feedback',
      value: _voiceOver,
      onChanged: (value) {
        setState(() => _voiceOver = value);
        if (value) {
          AccessibilityUtils.announceToScreenReader(
            'VoiceOver enabled',
            hint: 'Voice control',
          );
        }
      },
    );
  }

  /// Build switch control toggle.
  Widget _buildSwitchControlToggle() {
    return _buildToggleSetting(
      label: 'Switch Control',
      hint: 'Control with external switches',
      value: _switchControl,
      onChanged: (value) {
        setState(() => _switchControl = value);
        if (value) {
          AccessibilityUtils.announceToScreenReader(
            'Switch control enabled',
            hint: 'Accessibility feature',
          );
        }
      },
    );
  }

  /// Build voice control toggle.
  Widget _buildVoiceControlToggle() {
    return _buildToggleSetting(
      label: 'Voice Control',
      hint: 'Control with voice commands',
      value: _voiceControl,
      onChanged: (value) {
        setState(() => _voiceControl = value);
        if (value) {
          AccessibilityUtils.announceToScreenReader(
            'Voice control enabled',
            hint: 'Accessibility feature',
          );
        }
      },
    );
  }

  /// Build gesture sensitivity slider.
  Widget _buildGestureSensitivitySlider() {
    return _buildSliderSetting(
      label: 'Gesture Sensitivity',
      hint: 'Adjust sensitivity for touch gestures',
      value: 50.0,
      min: 10.0,
      max: 100.0,
      onChanged: (value) {
        // Handle gesture sensitivity change
      },
    );
  }

  /// Build double tap timeout slider.
  Widget _buildDoubleTapTimeoutSlider() {
    return _buildSliderSetting(
      label: 'Double Tap Timeout',
      hint: 'Adjust time for double tap detection',
      value: 300.0,
      min: 100.0,
      max: 1000.0,
      onChanged: (value) {
        // Handle double tap timeout change
      },
    );
  }

  /// Build long press timeout slider.
  Widget _buildLongPressTimeoutSlider() {
    return _buildSliderSetting(
      label: 'Long Press Timeout',
      hint: 'Adjust time for long press detection',
      value: 500.0,
      min: 200.0,
      max: 2000.0,
      onChanged: (value) {
        // Handle long press timeout change
      },
    );
  }

  /// Build a toggle setting widget.
  Widget _buildToggleSetting({
    required String label,
    required String hint,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          title: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: AppTheme.textPrimary,
            ),
          ),
          subtitle: Text(
            hint,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
          trailing: FlutterSwitch(
            width: 60,
            height: 32,
            toggleSize: 26,
            value: value,
            onToggle: onChanged,
            activeColor: AppTheme.accent,
            inactiveColor: AppTheme.surfaceLight,
            activeToggleColor: Colors.white,
            inactiveToggleColor: AppTheme.textSecondary,
          ),
          onTap: () {
            onChanged(!value);
            HapticFeedback.selectionClick();
          },
        ),
      ),
    );
  }

  /// Build a slider setting widget.
  Widget _buildSliderSetting({
    required String label,
    required String hint,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          title: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: AppTheme.textPrimary,
            ),
          ),
          subtitle: Text(
            hint,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
          trailing: SizedBox(
            width: 120,
            child: Slider(
              value: value,
              min: min,
              max: max,
              onChanged: onChanged,
              activeColor: AppTheme.accent,
              inactiveColor: AppTheme.surfaceLight,
            ),
          ),
          onTap: () {
            // Handle slider tap
          },
        ),
      ),
    );
  }
}
