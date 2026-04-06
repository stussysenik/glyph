import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/canvas/canvas_screen.dart';
import 'shared/theme/app_theme.dart';
import 'shared/accessibility/accessibility_utils.dart';
import 'core/undo_redo.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Register keyboard shortcuts and accessibility features
  UndoRedoManager.registerShortcuts();
  AccessibilityUtils.registerKeyboardShortcuts(
    onUndo: () => {},
    onRedo: () => {},
    onShake: () => {},
  );

  // Lock to portrait — Stories are vertical
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Dark status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const ProviderScope(child: GlyphApp()));
}

class GlyphApp extends StatelessWidget {
  const GlyphApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Glyph',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const CanvasScreen(),
    );
  }
}
