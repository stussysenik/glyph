import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/export_engine.dart';
import '../../shared/theme/app_theme.dart';
import '../accessibility/accessibility_utils.dart';
import '../export/export_preview.dart';

/// Bottom sheet with export options: Instagram Stories, Save, Copy.
/// Updated with accessibility and gesture support.
class ExportSheet extends ConsumerStatefulWidget {
  final GlobalKey repaintKey;

  const ExportSheet({super.key, required this.repaintKey});

  @override
  ConsumerState<ExportSheet> createState() => _ExportSheetState();
}

class _ExportSheetState extends ConsumerState<ExportSheet> {
  bool _isExporting = false;
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      AccessibilityUtils.announceToScreenReader(
        'Export options',
        hint: 'Share to Instagram Stories, Save to Photos, or Copy',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Export Sticker',
      hint: 'Share to Instagram Stories, Save to Photos, or Copy',
      child: Focus(
        focusNode: _focusNode,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              AccessibilityUtils.accessibleButton(
                onPressed: () => Navigator.pop(context),
                label: 'Close export sheet',
                hint: 'Close export options',
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Title
              Semantics(
                label: 'Export Sticker',
                child: const Text(
                  'Export Sticker',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Export preview
              const ExportPreview(repaintKey: repaintKey),
              const SizedBox(height: 20),
              // Export options
              _buildExportOption(
                icon: Icons.camera_alt_rounded,
                label: 'Share to Instagram Stories',
                subtitle: 'Opens Instagram with your sticker',
                isPrimary: true,
                onTap: _shareToInstagram,
                accessibilityLabel: 'Share to Instagram Stories',
                accessibilityHint: 'Opens Instagram with your sticker',
              ),
              const SizedBox(height: 10),
              _buildExportOption(
                icon: Icons.photo_library_outlined,
                label: 'Save to Photos',
                subtitle: 'Transparent PNG to your camera roll',
                onTap: _saveToPhotos,
                accessibilityLabel: 'Save to Photos',
                accessibilityHint: 'Save transparent PNG to your camera roll',
              ),
              const SizedBox(height: 10),
              _buildExportOption(
                icon: Icons.copy_rounded,
                label: 'Copy Image',
                subtitle: 'Copy sticker to clipboard',
                onTap: _copyToClipboard,
                accessibilityLabel: 'Copy Image',
                accessibilityHint: 'Copy sticker to clipboard',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExportOption({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
    required String accessibilityLabel,
    required String accessibilityHint,
    bool isPrimary = false,
  }) {
    return AccessibilityUtils.accessibleButton(
      onPressed: _isExporting ? null : onTap,
      label: accessibilityLabel,
      hint: accessibilityHint,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isPrimary ? AppTheme.accent : AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isPrimary ? FontWeight.w600 : FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            if (_isExporting)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            else
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.white.withValues(alpha: 0.5),
              ),
          ],
        ),
      ),
    );
  }

  Future<Uint8List?> _renderPng() async {
    setState(() => _isExporting = true);
    final bytes = await ExportEngine.capturePng(widget.repaintKey);
    if (bytes == null && mounted) {
      setState(() => _isExporting = false);
      _showError('Failed to render sticker. Please try again.');
    }
    return bytes;
  }

  Future<void> _shareToInstagram() async {
    final bytes = await _renderPng();
    if (bytes == null) return;

    // Always save to camera roll as backup
    await ExportEngine.saveToGallery(bytes);

    final success = await ExportEngine.shareToInstagramStories(bytes);
    if (mounted) {
      setState(() => _isExporting = false);
      if (success) {
        HapticFeedback.mediumImpact();
        AccessibilityUtils.announceSuccess('Shared to Instagram Stories');
        Navigator.pop(context);
      } else {
        _showError(
          "Instagram isn't installed or couldn't be opened. "
          "Your sticker has been saved to Photos instead.",
        );
      }
    }
  }

  Future<void> _saveToPhotos() async {
    final bytes = await _renderPng();
    if (bytes == null) return;

    final success = await ExportEngine.saveToGallery(bytes);
    if (mounted) {
      setState(() => _isExporting = false);
      Navigator.pop(context);
      if (success) {
        HapticFeedback.mediumImpact();
        AccessibilityUtils.announceSuccess('Saved to Photos');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saved to Photos!'),
            backgroundColor: AppTheme.success,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        _showError(
            'Could not save to Photos. Check your photo library permissions in Settings.');
      }
    }
  }

  Future<void> _copyToClipboard() async {
    final bytes = await _renderPng();
    if (bytes == null) return;

    await ExportEngine.copyToClipboard(bytes);
    if (mounted) {
      setState(() => _isExporting = false);
      Navigator.pop(context);
      HapticFeedback.mediumImpact();
      AccessibilityUtils.announceSuccess('Copied to clipboard');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Copied!'),
          backgroundColor: AppTheme.success,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    AccessibilityUtils.announceError(message);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.error,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
