import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'font_manager.dart';

/// The complete styling + content state for the text canvas.
class CanvasModel {
  final String text;
  final FontEntry? selectedFont;
  final double fontSize;
  final Color textColor;
  final TextAlign alignment;
  final double letterSpacing;
  final double rotation;
  final List<CustomGuide> guides;
  final int undoStateId;

  const CanvasModel({
    this.text = '',
    this.selectedFont,
    this.fontSize = 64.0,
    this.textColor = Colors.white,
    this.alignment = TextAlign.center,
    this.letterSpacing = 0.0,
    this.rotation = 0.0,
    this.guides = const [],
    this.undoStateId = 0,
  });

  CanvasModel copyWith({
    String? text,
    FontEntry? selectedFont,
    double? fontSize,
    Color? textColor,
    TextAlign? alignment,
    double? letterSpacing,
    double? rotation,
    List<CustomGuide>? guides,
    int? undoStateId,
  }) {
    return CanvasModel(
      text: text ?? this.text,
      selectedFont: selectedFont ?? this.selectedFont,
      fontSize: fontSize ?? this.fontSize,
      textColor: textColor ?? this.textColor,
      alignment: alignment ?? this.alignment,
      letterSpacing: letterSpacing ?? this.letterSpacing,
      rotation: rotation ?? this.rotation,
      guides: guides ?? this.guides,
      undoStateId: undoStateId ?? this.undoStateId,
    );
  }

  /// Build the TextStyle from current state.
  /// For bundled Google Fonts, caller should wrap with GoogleFonts.
  TextStyle get textStyle => TextStyle(
        fontFamily: selectedFont?.familyName,
        fontSize: fontSize,
        color: textColor,
        letterSpacing: letterSpacing,
        height: 1.2,
      );

  /// Get the rotation in degrees (0-360)
  double get normalizedRotation => (rotation % 360 + 360) % 360;

  /// Check if rotation is at a cardinal angle (0°, 90°, 180°, 270°)
  bool get isAtCardinalAngle => [0.0, 90.0, 180.0, 270.0].contains(normalizedRotation);

  /// Snap rotation to nearest cardinal angle
  CanvasModel snapRotation() {
    final snapped = RotationSnapEngine.snapAngle(rotation);
    return copyWith(rotation: snapped);
  }
}

import 'undo_redo.dart';

class CanvasNotifier extends StateNotifier<CanvasModel> {
  final UndoRedoManager _undoRedoManager = UndoRedoManager();

  CanvasNotifier() : super(const CanvasModel()) {
    _undoRedoManager.addState(state);
  }

  void setText(String text) {
    _undoRedoManager.addState(state);
    state = state.copyWith(text: text);
  }

  void setFont(FontEntry font) {
    _undoRedoManager.addState(state);
    state = state.copyWith(selectedFont: font);
  }

  void setFontSize(double size) {
    _undoRedoManager.addState(state);
    state = state.copyWith(fontSize: size);
  }

  void setTextColor(Color color) {
    _undoRedoManager.addState(state);
    state = state.copyWith(textColor: color);
  }

  void setAlignment(TextAlign align) {
    _undoRedoManager.addState(state);
    state = state.copyWith(alignment: align);
  }

  void setLetterSpacing(double spacing) {
    _undoRedoManager.addState(state);
    state = state.copyWith(letterSpacing: spacing);
  }

  void setRotation(double rotation) {
    _undoRedoManager.addState(state);
    state = state.copyWith(rotation: rotation);
  }

  void undo() {
    final previousState = _undoRedoManager.undo();
    if (previousState != null) {
      state = previousState;
    }
  }

  void redo() {
    final nextState = _undoRedoManager.redo();
    if (nextState != null) {
      state = nextState;
    }
  }

  bool canUndo() => _undoRedoManager.canUndo();
  bool canRedo() => _undoRedoManager.canRedo();
}

final canvasProvider = StateNotifierProvider<CanvasNotifier, CanvasModel>(
  (ref) => CanvasNotifier(),
);
