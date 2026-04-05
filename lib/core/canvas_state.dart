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

  const CanvasModel({
    this.text = '',
    this.selectedFont,
    this.fontSize = 64.0,
    this.textColor = Colors.white,
    this.alignment = TextAlign.center,
    this.letterSpacing = 0.0,
  });

  CanvasModel copyWith({
    String? text,
    FontEntry? selectedFont,
    double? fontSize,
    Color? textColor,
    TextAlign? alignment,
    double? letterSpacing,
  }) {
    return CanvasModel(
      text: text ?? this.text,
      selectedFont: selectedFont ?? this.selectedFont,
      fontSize: fontSize ?? this.fontSize,
      textColor: textColor ?? this.textColor,
      alignment: alignment ?? this.alignment,
      letterSpacing: letterSpacing ?? this.letterSpacing,
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
}

class CanvasNotifier extends StateNotifier<CanvasModel> {
  CanvasNotifier() : super(const CanvasModel());

  void setText(String text) => state = state.copyWith(text: text);
  void setFont(FontEntry font) => state = state.copyWith(selectedFont: font);
  void setFontSize(double size) => state = state.copyWith(fontSize: size);
  void setTextColor(Color color) => state = state.copyWith(textColor: color);
  void setAlignment(TextAlign align) => state = state.copyWith(alignment: align);
  void setLetterSpacing(double spacing) =>
      state = state.copyWith(letterSpacing: spacing);
}

final canvasProvider = StateNotifierProvider<CanvasNotifier, CanvasModel>(
  (ref) => CanvasNotifier(),
);
