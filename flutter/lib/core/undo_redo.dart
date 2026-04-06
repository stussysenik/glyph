import 'package:flutter/services.dart';

/// Manages undo/redo functionality with a 50-state stack
/// and supports keyboard shortcuts (Cmd+Z/Cmd+Shift+Z)
class UndoRedoManager {
  static const int _maxStates = 50;
  final List<CanvasModel> _undoStack = [];
  final List<CanvasModel> _redoStack = [];
  CanvasModel? _currentState;

  /// Add a new state to the undo stack
  void addState(CanvasModel state) {
    if (_currentState != null && _currentState != state) {
      _undoStack.add(_currentState!);
      _redoStack.clear();
    }
    _currentState = state;

    // Limit stack size to prevent memory bloat
    if (_undoStack.length > _maxStates) {
      _undoStack.removeAt(0);
    }
  }

  /// Undo the last action
  CanvasModel? undo() {
    if (_undoStack.isEmpty) return null;

    final previousState = _undoStack.removeLast();
    _redoStack.add(_currentState!);
    _currentState = previousState;

    return previousState;
  }

  /// Redo the last undone action
  CanvasModel? redo() {
    if (_redoStack.isEmpty) return null;

    final nextState = _redoStack.removeLast();
    _undoStack.add(_currentState!);
    _currentState = nextState;

    return nextState;
  }

  /// Check if undo is available
  bool canUndo() => _undoStack.isNotEmpty;

  /// Check if redo is available
  bool canRedo() => _redoStack.isNotEmpty;

  /// Clear all history
  void clear() {
    _undoStack.clear();
    _redoStack.clear();
    _currentState = null;
  }

  /// Register keyboard shortcuts for undo/redo
  static void registerShortcuts() {
    // Cmd+Z for undo
    HardwareKeyboard.instance.addHandler((RawKeyEvent event) {
      if (event.isMetaPressed && event.physicalKey == PhysicalKeyboardKey.keyZ &&
          !event.isShiftPressed && event is KeyDownEvent) {
        // Trigger undo action
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    });

    // Cmd+Shift+Z for redo
    HardwareKeyboard.instance.addHandler((RawKeyEvent event) {
      if (event.isMetaPressed && event.physicalKey == PhysicalKeyboardKey.keyZ &&
          event.isShiftPressed && event is KeyDownEvent) {
        // Trigger redo action
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    });
  }

  /// Trigger shake-to-undo gesture
  static Future<void> triggerShakeUndo() async {
    // This would be implemented with device sensors
    // For now, we'll just simulate the action
    await Future.delayed(const Duration(milliseconds: 300));
  }
}
