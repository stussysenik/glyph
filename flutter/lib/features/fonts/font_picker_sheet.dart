import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/canvas_state.dart';
import '../../core/font_manager.dart';
import '../../shared/theme/app_theme.dart';
import '../accessibility/accessibility_utils.dart';

/// Bottom sheet showing available fonts with live previews.
/// Updated with accessibility and gesture support.
class FontPickerSheet extends ConsumerStatefulWidget {
  const FontPickerSheet({super.key});

  @override
  ConsumerState<FontPickerSheet> createState() => _FontPickerSheetState();
}

class _FontPickerSheetState extends ConsumerState<FontPickerSheet> {
  bool _showLicenseNotice = false;
  final _focusNode = FocusNode();
  final _importButtonFocusNode = FocusNode();
  final _gestureHandler = GestureHandler(
    context: context,
    onDoubleTap: () => _handleDoubleTap(),
    onLongPress: () => _handleLongPress(),
  );

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
    _importButtonFocusNode.addListener(_onImportButtonFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _importButtonFocusNode.removeListener(_onImportButtonFocusChange);
    _focusNode.dispose();
    _importButtonFocusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      AccessibilityUtils.announceToScreenReader(
        'Font picker',
        hint: 'Select a font for your story',
      );
    }
  }

  void _onImportButtonFocusChange() {
    if (_importButtonFocusNode.hasFocus) {
      AccessibilityUtils.announceToScreenReader(
        'Import font button',
        hint: 'Import custom font from device',
      );
    }
  }

  void _handleDoubleTap() {
    // Could implement double tap to quickly scroll or select
    AccessibilityUtils.announceToScreenReader(
      'Double tapped in font picker',
      hint: 'Quick actions available',
    );
  }

  void _handleLongPress() {
    AccessibilityUtils.announceToScreenReader(
      'Long press in font picker',
      hint: 'Context menu options available',
    );
  }

  @override
  Widget build(BuildContext context) {
    final fonts = ref.watch(fontListProvider);
    final canvas = ref.watch(canvasProvider);
    final previewText =
        canvas.text.isEmpty ? 'The quick brown fox' : canvas.text;

    final customFonts = fonts.where((f) => !f.isBundled).toList();
    final bundledFonts = fonts.where((f) => f.isBundled).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return Semantics(
          label: 'Font Picker',
          hint: 'Select a font for your story',
          child: Focus(
            focusNode: _focusNode,
            child: Container(
              decoration: const BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  // Handle bar
                  AccessibilityUtils.accessibleButton(
                    onPressed: () => Navigator.pop(context),
                    label: 'Close font picker',
                    hint: 'Close font selection',
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12, bottom: 8),
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppTheme.textSecondary.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                  // Title + Import button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Semantics(
                          label: 'Fonts',
                          child: const Text(
                            'Fonts',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        AccessibilityUtils.accessibleButton(
                          onPressed: _importFont,
                          focusNode: _importButtonFocusNode,
                          label: 'Import Font Button',
                          hint: 'Import custom font from device',
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppTheme.accent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add, size: 18, color: Colors.white),
                                SizedBox(width: 4),
                                Text(
                                  'Import',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: AppTheme.divider, height: 1),
                  // Font list
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.only(top: 8),
                      children: [
                        if (customFonts.isNotEmpty) ...[
                          _sectionHeader('Your Fonts'),
                          ...customFonts.map((f) => _fontTile(f, previewText)),
                        ],
                        _sectionHeader('Built-in'),
                        ...bundledFonts.map((f) => _fontTile(f, previewText)),
                      ],
                    ),
                  ),
                  // License notice for first import
                  if (_showLicenseNotice)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      color: AppTheme.surfaceLight,
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline,
                              color: AppTheme.textSecondary, size: 18),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Make sure you have the right to use imported fonts for social media content.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                          AccessibilityUtils.accessibleButton(
                            onPressed: () => setState(() => _showLicenseNotice = false),
                            label: 'Close license notice',
                            hint: 'Dismiss this information',
                            child: const Icon(Icons.close,
                                color: AppTheme.textSecondary, size: 18),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppTheme.textSecondary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _fontTile(FontEntry font, String previewText) {
    final canvas = ref.read(canvasProvider);
    final isSelected = canvas.selectedFont?.familyName == font.familyName;

    // Use Google Fonts for bundled fonts, custom family for imported
    TextStyle previewStyle;
    if (font.isBundled) {
      previewStyle = _googleFontStyle(font.familyName, 22);
    } else {
      previewStyle = TextStyle(
        fontFamily: font.familyName,
        fontSize: 22,
        color: AppTheme.textPrimary,
      );
    }

    return AccessibilityUtils.accessibleListItem(
      label: font.displayName,
      hint: 'Select ${font.displayName} font',
      onPressed: () {
        HapticFeedback.selectionClick();
        ref.read(canvasProvider.notifier).setFont(font);
        Navigator.pop(context);
        AccessibilityUtils.announceToScreenReader(
          'Selected ${font.displayName} font',
          hint: 'Font applied to story',
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        color: isSelected
            ? AppTheme.accent.withValues(alpha: 0.1)
            : Colors.transparent,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    previewText,
                    style: previewStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    font.displayName,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppTheme.accent, size: 22),
            if (!font.isBundled) ...[
              const SizedBox(width: 8),
              AccessibilityUtils.accessibleButton(
                onPressed: () => _confirmDelete(font),
                label: 'Delete ${font.displayName}',
                hint: 'Remove font from library',
                child: const Icon(Icons.more_horiz,
                    color: AppTheme.textSecondary, size: 20),
              ),
            ],
          ],
        ),
      ),
    );
  }

  TextStyle _googleFontStyle(String familyName, double fontSize) {
    switch (familyName) {
      case 'Playfair Display':
        return GoogleFonts.playfairDisplay(
            fontSize: fontSize, color: AppTheme.textPrimary);
      case 'Space Grotesk':
        return GoogleFonts.spaceGrotesk(
            fontSize: fontSize, color: AppTheme.textPrimary);
      case 'Archivo Black':
        return GoogleFonts.archivoBlack(
            fontSize: fontSize, color: AppTheme.textPrimary);
      case 'Caveat':
        return GoogleFonts.caveat(
            fontSize: fontSize, color: AppTheme.textPrimary);
      case 'DM Serif Display':
        return GoogleFonts.dmSerifDisplay(
            fontSize: fontSize, color: AppTheme.textPrimary);
      default:
        return TextStyle(fontSize: fontSize, color: AppTheme.textPrimary);
    }
  }

  Future<void> _importFont() async {
    final notifier = ref.read(fontListProvider.notifier);
    final entry = await notifier.importFont();
    if (entry != null && mounted) {
      // Auto-select the newly imported font
      ref.read(canvasProvider.notifier).setFont(entry);
      // Show license notice on first import
      setState(() => _showLicenseNotice = true);
      AccessibilityUtils.announceToScreenReader(
        'Imported ${entry.displayName} font',
        hint: 'Font added to library',
      );
    } else if (entry == null && mounted) {
      AccessibilityUtils.announceError(
        "Couldn't load this font file. Make sure it's a valid .ttf or .otf.",
      );
    }
  }

  Future<void> _confirmDelete(FontEntry font) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Remove Font?'),
        content: Text('Remove "${font.displayName}" from your library?'),
        actions: [
          AccessibilityUtils.accessibleButton(
            onPressed: () => Navigator.pop(ctx, false),
            label: 'Cancel',
            hint: 'Cancel font removal',
            child: const Text('Cancel'),
          ),
          AccessibilityUtils.accessibleButton(
            onPressed: () => Navigator.pop(ctx, true),
            label: 'Remove',
            hint: 'Confirm font removal',
            child: const Text('Remove', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(fontListProvider.notifier).removeFont(font);
      AccessibilityUtils.announceToScreenReader(
        'Removed ${font.displayName} font',
        hint: 'Font removed from library',
      );
    }
  }
}
