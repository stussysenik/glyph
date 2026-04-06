import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/canvas_state.dart';
import '../../shared/theme/app_theme.dart';
import '../accessibility/accessibility_utils.dart';
import '../accessibility/gesture_handler.dart';

/// Which style control is currently expanded.
enum StyleTab { none, size, color, spacing, align, rotation }

/// Bottom style control bar — progressive disclosure.
/// Collapsed: icon bar. Tap to expand individual controls.
class StyleControls extends ConsumerStatefulWidget {
  const StyleControls({super.key});

  @override
  ConsumerState<StyleControls> createState() => _StyleControlsState();
}

class _StyleControlsState extends ConsumerState<StyleControls> {
  StyleTab _activeTab = StyleTab.none;
  Timer? _autoHideTimer;
  final _gestureHandler = GestureHandler(
    context: context,
    onDoubleTap: () => _handleDoubleTap(),
    onLongPress: () => _handleLongPress(),
  );

  @override
  void initState() {
    super.initState();
    _startAutoHideTimer();
  }

  @override
  void dispose() {
    _autoHideTimer?.cancel();
    super.dispose();
  }

  void _startAutoHideTimer() {
    _autoHideTimer?.cancel();
    _autoHideTimer = Timer(const Duration(seconds: 3), () {
      if (_activeTab != StyleTab.none) {
        setState(() => _activeTab = StyleTab.none);
        AccessibilityUtils.announceToScreenReader(
          'Style controls auto-hidden',
          hint: 'Toolbar auto-hiding after 3 seconds of inactivity',
        );
      }
    });
  }

  void _resetAutoHideTimer() {
    _startAutoHideTimer();
  }

  @override
  Widget build(BuildContext context) {
    final canvas = ref.watch(canvasProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Expanded control panel
        AnimatedSize(
          duration: IaWriterPolish.getAnimationDuration(
            const Duration(milliseconds: 200),
          ),
          curve: IaWriterPolish.getAnimationCurve(Curves.easeOut),
          child: _activeTab == StyleTab.none
              ? const SizedBox.shrink()
              : Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: const BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: _buildExpandedControl(canvas),
                ),
        ),
        // Icon bar
        AccessibilityUtils.accessibleButton(
          onPressed: () => _toggleControlPanel(),
          label: 'Style Controls',
          hint: 'Open style adjustment panel',
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: _activeTab == StyleTab.none
                  ? BorderRadius.circular(16)
                  : BorderRadius.zero,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _tabButton(
                  icon: Icons.text_fields,
                  label: '${canvas.fontSize.round()}',
                  tab: StyleTab.size,
                ),
                _tabButton(
                  iconWidget: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: canvas.textColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: canvas.textColor == Colors.black
                            ? AppTheme.textSecondary
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                  ),
                  label: 'Color',
                  tab: StyleTab.color,
                ),
                _tabButton(
                  icon: Icons.space_bar,
                  label: canvas.letterSpacing.toStringAsFixed(1),
                  tab: StyleTab.spacing,
                ),
                _tabButton(
                  icon: _alignmentIcon(canvas.alignment),
                  label: 'Align',
                  tab: StyleTab.align,
                ),
                _tabButton(
                  icon: Icons.rotate_right,
                  label: '${canvas.rotation.round()}°',
                  tab: StyleTab.rotation,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _toggleControlPanel() {
    setState(() {
      _activeTab = _activeTab == StyleTab.none ? StyleTab.size : StyleTab.none;
    });
    _resetAutoHideTimer();
    if (_activeTab != StyleTab.none) {
      AccessibilityUtils.announceToScreenReader(
        'Style controls opened',
        hint: 'Adjust font size, color, spacing, alignment and rotation',
      );
    }
  }

  void _handleDoubleTap() {
    // Double tap to quickly toggle between tabs
    if (_activeTab != StyleTab.none) {
      setState(() => _activeTab = StyleTab.none);
      AccessibilityUtils.announceToScreenReader(
        'Style controls closed',
        hint: 'Double tapped to close',
      );
    }
  }

  void _handleLongPress() {
    AccessibilityUtils.announceToScreenReader(
      'Long press on style controls',
      hint: 'Context menu options available',
    );
  }

  Widget _tabButton({
    IconData? icon,
    Widget? iconWidget,
    required String label,
    required StyleTab tab,
  }) {
    final isActive = _activeTab == tab;

    return AccessibilityUtils.accessibleButton(
      onPressed: () {
        HapticFeedback.selectionClick();
        setState(() {
          _activeTab = isActive ? StyleTab.none : tab;
        });
        _resetAutoHideTimer();
        if (!isActive) {
          AccessibilityUtils.announceToScreenReader(
            'Opening $label controls',
            hint: 'Adjust $label settings',
          );
        }
      },
      label: label,
      hint: isActive ? 'Close $label controls' : 'Open $label controls',
      child: AnimatedContainer(
        duration: IaWriterPolish.getAnimationDuration(
          const Duration(milliseconds: 150),
        ),
        curve: IaWriterPolish.getAnimationCurve(Curves.easeOut),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.accent.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            iconWidget ??
                Icon(
                  icon,
                  size: 22,
                  color: isActive ? AppTheme.accent : AppTheme.textSecondary,
                ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isActive ? AppTheme.accent : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedControl(CanvasModel canvas) {
    switch (_activeTab) {
      case StyleTab.size:
        return _sizeSlider(canvas);
      case StyleTab.color:
        return _colorGrid(canvas);
      case StyleTab.spacing:
        return _spacingSlider(canvas);
      case StyleTab.align:
        return _alignmentButtons(canvas);
      case StyleTab.rotation:
        return _rotationSlider(canvas);
      case StyleTab.none:
        return const SizedBox.shrink();
    }
  }

  Widget _sizeSlider(CanvasModel canvas) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Font Size',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text('24',
                style:
                    TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            Expanded(
              child: AccessibilityUtils.accessibleSlider(
                value: canvas.fontSize,
                min: 24,
                max: 200,
                onChanged: (v) {
                  ref.read(canvasProvider.notifier).setFontSize(v);
                },
                label: 'Font Size Slider',
                hint: 'Adjust font size from 24 to 200',
              ),
            ),
            const Text('200',
                style:
                    TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          ],
        ),
      ],
    );
  }

  Widget _colorGrid(CanvasModel canvas) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Text Color',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: AppTheme.presetColors.map((color) {
            final isSelected = canvas.textColor.toARGB32() == color.toARGB32();
            return AccessibilityUtils.accessibleColorButton(
              color: color,
              label: 'Color option',
              hint: 'Select this color for text',
              isSelected: isSelected,
              onPressed: () {
                HapticFeedback.selectionClick();
                ref.read(canvasProvider.notifier).setTextColor(color);
                AccessibilityUtils.announceToScreenReader(
                  'Selected ${color.value.toRadixString(16)} color',
                  hint: 'Text color changed',
                );
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _spacingSlider(CanvasModel canvas) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Letter Spacing',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text('-5',
                style:
                    TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            Expanded(
              child: AccessibilityUtils.accessibleSlider(
                value: canvas.letterSpacing,
                min: -5,
                max: 20,
                onChanged: (v) {
                  ref.read(canvasProvider.notifier).setLetterSpacing(v);
                },
                label: 'Letter Spacing Slider',
                hint: 'Adjust letter spacing from -5 to 20',
              ),
            ),
            const Text('20',
                style:
                    TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          ],
        ),
      ],
    );
  }

  Widget _rotationSlider(CanvasModel canvas) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Rotation',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text('0°',
                style:
                    TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            Expanded(
              child: AccessibilityUtils.accessibleSlider(
                value: canvas.rotation,
                min: 0,
                max: 360,
                onChanged: (v) {
                  ref.read(canvasProvider.notifier).setRotation(v);
                },
                label: 'Rotation Slider',
                hint: 'Adjust rotation from 0 to 360 degrees',
              ),
            ),
            const Text('360°',
                style:
                    TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _snapButton(
              icon: Icons.rotate_left,
              label: 'Snap Left',
              onPressed: () {
                final snapped = canvas.snapRotation();
                ref.read(canvasProvider.notifier).setRotation(snapped.rotation);
                RotationSnapEngine.provideHapticFeedback();
                AccessibilityUtils.announceToScreenReader(
                  'Rotation snapped to cardinal angle',
                  hint: 'Rotation set to ${RotationSnapEngine.getDegreeBadge(snapped.rotation)}',
                );
              },
            ),
            const SizedBox(width: 16),
            _snapButton(
              icon: Icons.rotate_right,
              label: 'Snap Right',
              onPressed: () {
                final snapped = canvas.snapRotation();
                ref.read(canvasProvider.notifier).setRotation(snapped.rotation);
                RotationSnapEngine.provideHapticFeedback();
                AccessibilityUtils.announceToScreenReader(
                  'Rotation snapped to cardinal angle',
                  hint: 'Rotation set to ${RotationSnapEngine.getDegreeBadge(snapped.rotation)}',
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _alignmentButtons(CanvasModel canvas) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _alignButton(Icons.format_align_left, TextAlign.left, canvas),
        const SizedBox(width: 24),
        _alignButton(Icons.format_align_center, TextAlign.center, canvas),
        const SizedBox(width: 24),
        _alignButton(Icons.format_align_right, TextAlign.right, canvas),
      ],
    );
  }

  Widget _alignButton(
      IconData icon, TextAlign align, CanvasModel canvas) {
    final isSelected = canvas.alignment == align;

    return AccessibilityUtils.accessibleButton(
      onPressed: () {
        HapticFeedback.selectionClick();
        ref.read(canvasProvider.notifier).setAlignment(align);
        AccessibilityUtils.announceToScreenReader(
          'Set text alignment to ${align.name}',
          hint: 'Text alignment changed',
        );
      },
      label: 'Alignment button',
      hint: 'Set text alignment to ${align.name}',
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.accent.withValues(alpha: 0.15) : AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: isSelected ? AppTheme.accent : AppTheme.textSecondary,
          size: 24,
        ),
      ),
    );
  }

  Widget _snapButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return AccessibilityUtils.accessibleButton(
      onPressed: onPressed,
      label: label,
      hint: 'Snap rotation to cardinal angle',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.accent.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: AppTheme.accent,
              size: 20,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _alignmentIcon(TextAlign align) {
    switch (align) {
      case TextAlign.left:
        return Icons.format_align_left;
      case TextAlign.right:
        return Icons.format_align_right;
      default:
        return Icons.format_align_center;
    }
  }
}
