import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/canvas_state.dart';
import '../../core/font_manager.dart';
import '../../shared/theme/app_theme.dart';
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
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
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
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    ref.read(canvasProvider.notifier).setText(_textController.text);
  }

  @override
  Widget build(BuildContext context) {
    final canvas = ref.watch(canvasProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: AppTheme.background,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
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
                child: TextField(
                  controller: _textController,
                  focusNode: _focusNode,
                  maxLines: null,
                  autofocus: false,
                  decoration: const InputDecoration(border: InputBorder.none),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(CanvasModel canvas) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Font picker button
          GestureDetector(
            onTap: _showFontPicker,
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
          // Export button
          GestureDetector(
            onTap: canvas.text.isEmpty ? null : _showExportSheet,
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

    return GestureDetector(
      onTap: () {
        if (_isEditing) {
          _focusNode.unfocus();
          setState(() => _isEditing = false);
        } else {
          _focusNode.requestFocus();
          setState(() => _isEditing = true);
        }
      },
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
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ExportSheet(repaintKey: _repaintKey),
    );
  }
}
