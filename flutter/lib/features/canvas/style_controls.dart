import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/canvas_state.dart';
import '../../shared/theme/app_theme.dart';

/// Which style control is currently expanded.
enum StyleTab { none, size, color, spacing, align }

/// Bottom style control bar — progressive disclosure.
/// Collapsed: icon bar. Tap to expand individual controls.
class StyleControls extends ConsumerStatefulWidget {
  const StyleControls({super.key});

  @override
  ConsumerState<StyleControls> createState() => _StyleControlsState();
}

class _StyleControlsState extends ConsumerState<StyleControls> {
  StyleTab _activeTab = StyleTab.none;

  @override
  Widget build(BuildContext context) {
    final canvas = ref.watch(canvasProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Expanded control panel
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
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
        Container(
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
            ],
          ),
        ),
      ],
    );
  }

  Widget _tabButton({
    IconData? icon,
    Widget? iconWidget,
    required String label,
    required StyleTab tab,
  }) {
    final isActive = _activeTab == tab;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _activeTab = isActive ? StyleTab.none : tab;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
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
              child: Slider(
                value: canvas.fontSize,
                min: 24,
                max: 200,
                activeColor: AppTheme.accent,
                inactiveColor: AppTheme.surfaceLight,
                onChanged: (v) {
                  ref.read(canvasProvider.notifier).setFontSize(v);
                },
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
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                ref.read(canvasProvider.notifier).setTextColor(color);
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.accent
                        : (color == Colors.black
                            ? AppTheme.textSecondary
                            : Colors.transparent),
                    width: isSelected ? 2.5 : 1.5,
                  ),
                ),
                child: isSelected
                    ? Icon(Icons.check,
                        size: 18,
                        color: color.computeLuminance() > 0.5
                            ? Colors.black
                            : Colors.white)
                    : null,
              ),
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
              child: Slider(
                value: canvas.letterSpacing,
                min: -5,
                max: 20,
                activeColor: AppTheme.accent,
                inactiveColor: AppTheme.surfaceLight,
                onChanged: (v) {
                  ref.read(canvasProvider.notifier).setLetterSpacing(v);
                },
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
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        ref.read(canvasProvider.notifier).setAlignment(align);
      },
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
