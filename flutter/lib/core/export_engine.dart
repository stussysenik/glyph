import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';

/// Handles rendering the canvas to PNG and sharing to Instagram Stories.
class ExportEngine {
  /// Capture a RepaintBoundary widget as a transparent PNG.
  /// [pixelRatio] controls output resolution (3.0 = retina quality).
  static Future<Uint8List?> capturePng(
    GlobalKey repaintKey, {
    double pixelRatio = 3.0,
  }) async {
    try {
      final boundary = repaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;

      return byteData.buffer.asUint8List();
    } catch (e) {
      debugPrint('Export error: $e');
      return null;
    }
  }

  /// Save PNG bytes to the device's photo library.
  static Future<bool> saveToGallery(Uint8List pngBytes) async {
    try {
      final result = await ImageGallerySaverPlus.saveImage(
        pngBytes,
        quality: 100,
        name: 'glyph_${DateTime.now().millisecondsSinceEpoch}',
      );
      // The result is a map with 'isSuccess' key
      if (result is Map) {
        return result['isSuccess'] == true;
      }
      return result != null;
    } catch (e) {
      debugPrint('Gallery save error: $e');
      return false;
    }
  }

  /// Share a sticker image to Instagram Stories via the native platform channel.
  /// Returns true if Instagram was opened, false otherwise.
  static Future<bool> shareToInstagramStories(Uint8List stickerPngBytes) async {
    const channel = MethodChannel('com.glyphapp.glyph/instagram');
    try {
      final result = await channel.invokeMethod<bool>(
        'shareToInstagramStories',
        {'stickerImage': stickerPngBytes},
      );
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('Instagram share error: ${e.message}');
      return false;
    } on MissingPluginException {
      debugPrint('Instagram share: platform channel not implemented');
      return false;
    }
  }

  /// Copy image to clipboard.
  static Future<void> copyToClipboard(Uint8List pngBytes) async {
    // Flutter's clipboard doesn't natively support images,
    // so we use the platform channel for this too.
    const channel = MethodChannel('com.glyphapp.glyph/instagram');
    try {
      await channel.invokeMethod('copyImageToClipboard', {
        'imageData': pngBytes,
      });
    } catch (e) {
      debugPrint('Copy to clipboard error: $e');
    }
  }
}
