import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/canvas_state.dart';
import '../../core/font_manager.dart';
import '../../shared/theme/app_theme.dart';

/// Bottom sheet showing available fonts with live previews.
class FontPickerSheet extends ConsumerStatefulWidget {
  const FontPickerSheet({super.key});

  @override
  ConsumerState<FontPickerSheet> createState() => _FontPickerSheetState();
}

class _FontPickerSheetState extends ConsumerState<FontPickerSheet> {
  bool _showLicenseNotice = false;

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
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Padding(
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
              // Title + Import button
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Fonts',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    GestureDetector(
                      onTap: _importFont,
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
                      GestureDetector(
                        onTap: () => setState(() => _showLicenseNotice = false),
                        child: const Icon(Icons.close,
                            color: AppTheme.textSecondary, size: 18),
                      ),
                    ],
                  ),
                ),
            ],
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

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        ref.read(canvasProvider.notifier).setFont(font);
        Navigator.pop(context);
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
              GestureDetector(
                onTap: () => _confirmDelete(font),
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
    } else if (entry == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              "Couldn't load this font file. Make sure it's a valid .ttf or .otf."),
          backgroundColor: AppTheme.error,
        ),
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
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Remove', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(fontListProvider.notifier).removeFont(font);
    }
  }
}
