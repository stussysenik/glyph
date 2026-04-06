import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/canvas_state.dart';
import '../../core/font_manager.dart';
import '../../core/gestures/rotation_snap_engine.dart';
import '../../core/undo_redo.dart';
import '../../core/guides.dart';
import '../../shared/theme/app_theme.dart';
import '../accessibility/accessibility_utils.dart';
import '../export/export_sheet.dart';
import '../fonts/font_picker_sheet.dart';
import 'style_controls.dart';

/// The single main screen — type, style, export. That's it.
class CanvasScreen extends ConsumerStatefulWidget {
  const CanvasScreen({super.key});

  @override
  ConsumerState<CanvasScreen> createState() => _CanvasScreenState();
}

class _CanvasScreenState extends ConsumerState<CanvasScreen> {
  final _repaintKey = GlobalKey();
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  final _canvasFocusNode = FocusNode();
  bool _isEditing = false;
  double _currentRotation = 0.0;
  bool _showRotationBadge = false;
  Timer? _autoHideTimer;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChange);
    _canvasFocusNode.addListener(_onCanvasFocusChange);

    // Register keyboard shortcuts
    UndoRedoManager.registerShortcuts();

    // Auto-select first bundled font on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final fonts = ref.read(fontListProvider);
      if (fonts.isNotEmpty) {
        ref.read(canvasProvider.notifier).setFont(fonts.first);
      }
    });
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _canvasFocusNode.removeListener(_onCanvasFocusChange);
    _canvasFocusNode.dispose();
    _autoHideTimer?.cancel();
    super.dispose();
  }

  void _onTextChanged() {
    ref.read(canvasProvider.notifier).setText(_textController.text);
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      setState(() => _isEditing = true);
      AccessibilityUtils.announceToScreenReader(
        'Text editing mode',
        hint: 'Type your story text',
      );
    } else {
      setState(() => _isEditing = false);
    }
  }

  void _onCanvasFocusChange() {
    if (_canvasFocusNode.hasFocus) {
      AccessibilityUtils.announceToScreenReader(
        'Canvas area',
        hint: 'Tap to edit text or use gestures',
      );
    }
  }

  void _handleDoubleTap() {
    if (!_isEditing) {
      _focusNode.requestFocus();
      setState(() => _isEditing = true);
      AccessibilityUtils.announceToScreenReader(
        'Double tapped to edit text',
        hint: 'Text editing mode',
      );
    } else {
      // Double tap to snap rotation
      final canvas = ref.read(canvasProvider);
      if (canvas.rotation != 0.0) {
        ref.read(canvasProvider.notifier).setRotation(
          RotationSnapEngine.snapAngle(canvas.rotation)
        );
        RotationSnapEngine.provideHapticFeedback();
        AccessibilityUtils.announceToScreenReader(
          'Rotation snapped to cardinal angle',
          hint: 'Rotation set to ${RotationSnapEngine.getDegreeBadge(canvas.rotation)}',
        );
      }
    }
  }

  void _handleRotationGesture(double rotationDelta) {
    final newRotation = _currentRotation + rotationDelta;
    setState(() => _currentRotation = newRotation);
    ref.read(canvasProvider.notifier).setRotation(newRotation);

    // Show rotation badge
    setState(() => _showRotationBadge = true);
    _autoHideTimer?.cancel();
    _autoHideTimer = Timer(const Duration(milliseconds: 500), () {
      setState(() => _showRotationBadge = false);
    });

    // Provide haptic feedback for rotation
    if (RotationSnapEngine.shouldSnap(_currentRotation, newRotation)) {
      RotationSnapEngine.provideHapticFeedback();
    }
  }

  void _handleUndo() {
    ref.read(canvasProvider.notifier).undo();
    AccessibilityUtils.announceToScreenReader(
      'Undo action performed',
      hint: 'Reverted to previous state',
    );
  }

  void _handleRedo() {
    ref.read(canvasProvider.notifier).redo();
    AccessibilityUtils.announceToScreenReader(
      'Redo action performed',
      hint: 'Restored previous state',
    );
  }

  void _handleShakeGesture() {
    // Simulate shake-to-undo
    _handleUndo();
  }

  @override
  Widget build(BuildContext context) {
    final canvas = ref.watch(canvasProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: AppTheme.background,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Focus(
          focusNode: _canvasFocusNode,
          child: GestureDetector(
            onTap: () {
              if (_isEditing) {
                _focusNode.unfocus();
                setState(() => _isEditing = false);
              } else {
                _focusNode.requestFocus();
                setState(() => _isEditing = true);
              }
            },
            onDoubleTap: _handleDoubleTap,
            onLongPress: () {
              AccessibilityUtils.announceToScreenReader(
                'Long press detected',
                hint: 'Context menu available',
              );
            },
            child: Stack(
              children: [
                // Main content
                Column(
                  children: [
                    _buildTopBar(canvas),
                    Expanded(child: _buildCanvas(canvas)),
                    // Push controls above keyboard
                    AnimatedPadding(
                      duration: const Duration(milliseconds: 200),
                      padding: EdgeInsets.only(
                        bottom: bottomInset > 0 ? bottomInset : 0,
                      ),
                      child: const StyleControls(),
                    ),
                    if (bottomInset == 0) const SizedBox(height: 16),
                  ],
                ),
                // Hidden text field — we use this for keyboard input
                Positioned(
                  left: -1000,
                  child: SizedBox(
                    width: 1,
                    height: 1,
                    child: AccessibilityUtils.accessibleTextField(
                      controller: _textController,
                      label: 'Story Text',
                      hint: 'Type your Instagram story text',
                      focusNode: _focusNode,
                      onChanged: _onTextChanged,
                    ),
                  ),
                ),
                // Rotation badge
                if (_showRotationBadge)
                  Positioned(
                    top: 80,
                    left: MediaQuery.of(context).size.width / 2 - 30,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.accent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        RotationSnapEngine.getDegreeBadge(_currentRotation),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(CanvasModel canvas) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Font picker button with accessibility support
          AccessibilityUtils.accessibleButton(
            onPressed: _showFontPicker,
            label: 'Font Picker',
            hint: 'Open font selection menu',
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    canvas.selectedFont?.displayName ?? 'Select Font',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.keyboard_arrow_down,
                      size: 18, color: AppTheme.textSecondary),
                ],
              ),
            ),
          ),
          const Spacer(),
          // Undo button
          if (ref.read(canvasProvider.notifier).canUndo())
            AccessibilityUtils.accessibleButton(
              onPressed: _handleUndo,
              label: 'Undo',
              hint: 'Undo last action',
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.undo,
                  size: 18,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          // Redo button
          if (ref.read(canvasProvider.notifier).canRedo())
            AccessibilityUtils.accessibleButton(
              onPressed: _handleRedo,
              label: 'Redo',
              hint: 'Redo last action',
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.redo,
                  size: 18,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          // Export button with accessibility support
          AccessibilityUtils.accessibleButton(
            onPressed: canvas.text.isEmpty ? null : _showExportSheet,
            label: 'Export Button',
            hint: canvas.text.isEmpty
                ? 'Add text to enable export'
                : 'Share to Instagram Stories',
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: canvas.text.isEmpty
                    ? AppTheme.surfaceLight
                    : AppTheme.accent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.ios_share,
                    size: 18,
                    color: canvas.text.isEmpty
                        ? AppTheme.textSecondary
                        : Colors.white,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Export',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: canvas.text.isEmpty
                          ? AppTheme.textSecondary
                          : Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCanvas(CanvasModel canvas) {
    final hasText = canvas.text.isNotEmpty;

    return AccessibilityUtils.accessibleButton(
      onPressed: () {
        if (_isEditing) {
          _focusNode.unfocus();
          setState(() => _isEditing = false);
        } else {
          _focusNode.requestFocus();
          setState(() => _isEditing = true);
        }
      },
      label: 'Canvas Area',
      hint: 'Tap to edit text or use gestures',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 32),
        color: Colors.transparent,
        child: Center(
          // This RepaintBoundary captures the text for PNG export.
          // Only the text is inside — no background, no chrome.
          child: RepaintBoundary(
            key: _repaintKey,
            child: hasText
                ? Text(
                    canvas.text,
                    style: _resolveTextStyle(canvas),
                    textAlign: canvas.alignment,
                  )
                : Text(
                    'Type something',
                    style: _resolveTextStyle(canvas).copyWith(
                      color: AppTheme.textSecondary.withValues(alpha: 0.4),
                    ),
                    textAlign: canvas.alignment,
                  ),
          ),
        ),
      ),
    );
  }

  /// Resolve the text style, using Google Fonts for bundled fonts
  /// and the loaded custom family for imported fonts.
  TextStyle _resolveTextStyle(CanvasModel canvas) {
    final font = canvas.selectedFont;
    if (font == null) return canvas.textStyle;

    if (font.isBundled) {
      return _googleFontTextStyle(font.familyName, canvas);
    }

    return canvas.textStyle;
  }

  TextStyle _googleFontTextStyle(String familyName, CanvasModel canvas) {
    final baseStyle = TextStyle(
      fontSize: canvas.fontSize,
      color: canvas.textColor,
      letterSpacing: canvas.letterSpacing,
      height: 1.2,
    );

    switch (familyName) {
      case 'Playfair Display':
        return GoogleFonts.playfairDisplay(textStyle: baseStyle);
      case 'Space Grotesk':
        return GoogleFonts.spaceGrotesk(textStyle: baseStyle);
      case 'Archivo Black':
        return GoogleFonts.archivoBlack(textStyle: baseStyle);
      case 'Caveat':
        return GoogleFonts.caveat(textStyle: baseStyle);
      case 'DM Serif Display':
        return GoogleFonts.dmSerifDisplay(textStyle: baseStyle);
      default:
        return baseStyle;
    }
  }

  void _showFontPicker() {
    _focusNode.unfocus();
    setState(() => _isEditing = false);
    AccessibilityUtils.announceToScreenReader(
      'Opening font picker',
      hint: 'Select a font for your story',
    );
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const FontPickerSheet(),
    );
  }

  void _showExportSheet() {
    _focusNode.unfocus();
    setState(() => _isEditing = false);
    HapticFeedback.mediumImpact();
    AccessibilityUtils.announceToScreenReader(
      'Opening export options',
      hint: 'Share to Instagram Stories or save to photos',
    );
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ExportSheet(repaintKey: _repaintKey),
    );
  }
}
