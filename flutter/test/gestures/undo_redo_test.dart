import 'package:flutter_test/flutter_test.dart';
import 'package:glyph/core/undo_redo.dart';

void main() {
  group('UndoRedoManager Tests', () {
    late UndoRedoManager undoRedoManager;
    late CanvasModel initialState;
    late CanvasModel modifiedState;
    late CanvasModel anotherState;

    setUp(() {
      undoRedoManager = UndoRedoManager();
      initialState = const CanvasModel(text: 'Initial text');
      modifiedState = initialState.copyWith(text: 'Modified text');
      anotherState = modifiedState.copyWith(text: 'Another modification');
    });

    test('initial state is null', () {
      expect(undoRedoManager.currentState, isNull);
    });

    test('addState sets current state', () {
      undoRedoManager.addState(initialState);
      expect(undoRedoManager.currentState, equals(initialState));
    });

    test('undo returns previous state', () {
      undoRedoManager.addState(initialState);
      undoRedoManager.addState(modifiedState);

      final previousState = undoRedoManager.undo();
      expect(previousState, equals(initialState));
      expect(undoRedoManager.currentState, equals(initialState));
    });

    test('redo returns next state', () {
      undoRedoManager.addState(initialState);
      undoRedoManager.addState(modifiedState);
      undoRedoManager.undo(); // Go back to initial

      final nextState = undoRedoManager.redo();
      expect(nextState, equals(modifiedState));
      expect(undoRedoManager.currentState, equals(modifiedState));
    });

    test('canUndo returns true when undo is available', () {
      undoRedoManager.addState(initialState);
      undoRedoManager.addState(modifiedState);

      expect(undoRedoManager.canUndo(), isTrue);
    });

    test('canUndo returns false when no undo available', () {
      expect(undoRedoManager.canUndo(), isFalse);
    });

    test('canRedo returns true when redo is available', () {
      undoRedoManager.addState(initialState);
      undoRedoManager.addState(modifiedState);
      undoRedoManager.undo(); // Go back to initial

      expect(undoRedoManager.canRedo(), isTrue);
    });

    test('canRedo returns false when no redo available', () {
      expect(undoRedoManager.canRedo(), isFalse);
    });

    test('clear removes all states', () {
      undoRedoManager.addState(initialState);
      undoRedoManager.addState(modifiedState);

      undoRedoManager.clear();
      expect(undoRedoManager.currentState, isNull);
      expect(undoRedoManager.canUndo(), isFalse);
      expect(undoRedoManager.canRedo(), isFalse);
    });

    test('stack size is limited to 50 states', () {
      // Add 60 states to exceed the limit
      for (int i = 0; i < 60; i++) {
        undoRedoManager.addState(
          CanvasModel(text: 'State $i'),
        );
      }

      // Should only have 50 states (last 50 added)
      expect(undoRedoManager._undoStack.length, equals(50));
    });

    test('undo/redo preserves all state properties', () {
      final state1 = CanvasModel(
        text: 'Text 1',
        fontSize: 32.0,
        textColor: Colors.red,
        alignment: TextAlign.left,
        letterSpacing: 1.0,
        rotation: 45.0,
      );

      final state2 = state1.copyWith(
        text: 'Text 2',
        fontSize: 64.0,
        textColor: Colors.blue,
        alignment: TextAlign.right,
        letterSpacing: 2.0,
        rotation: 90.0,
      );

      undoRedoManager.addState(state1);
      undoRedoManager.addState(state2);
      undoRedoManager.undo();

      final currentState = undoRedoManager.currentState;
      expect(currentState, isNotNull);
      expect(currentState!.text, equals('Text 1'));
      expect(currentState.fontSize, equals(32.0));
      expect(currentState.textColor, equals(Colors.red));
      expect(currentState.alignment, equals(TextAlign.left));
      expect(currentState.letterSpacing, equals(1.0));
      expect(currentState.rotation, equals(45.0));
    });

    test('multiple undo/redo operations work correctly', () {
      undoRedoManager.addState(initialState);
      undoRedoManager.addState(modifiedState);
      undoRedoManager.addState(anotherState);

      // Undo twice
      undoRedoManager.undo();
      undoRedoManager.undo();
      expect(undoRedoManager.currentState, equals(initialState));

      // Redo once
      undoRedoManager.redo();
      expect(undoRedoManager.currentState, equals(modifiedState));

      // Redo again
      undoRedoManager.redo();
      expect(undoRedoManager.currentState, equals(anotherState));

      // Undo once
      undoRedoManager.undo();
      expect(undoRedoManager.currentState, equals(modifiedState));
    });

    test('undo with no states does nothing', () {
      undoRedoManager.undo();
      expect(undoRedoManager.currentState, isNull);
    });

    test('redo with no states does nothing', () {
      undoRedoManager.redo();
      expect(undoRedoManager.currentState, isNull);
    });

    test('adding same state multiple times works correctly', () {
      undoRedoManager.addState(initialState);
      undoRedoManager.addState(initialState);
      undoRedoManager.addState(modifiedState);

      undoRedoManager.undo();
      expect(undoRedoManager.currentState, equals(initialState));

      undoRedoManager.undo();
      expect(undoRedoManager.currentState, equals(initialState));

      undoRedoManager.undo();
      expect(undoRedoManager.currentState, isNull);
    });

    test('adding state after undo clears redo stack', () {
      undoRedoManager.addState(initialState);
      undoRedoManager.addState(modifiedState);
      undoRedoManager.undo(); // Go back to initial

      // Redo should be available
      expect(undoRedoManager.canRedo(), isTrue);

      // Add new state - should clear redo stack
      undoRedoManager.addState(anotherState);

      // Redo should no longer be available
      expect(undoRedoManager.canRedo(), isFalse);
    });
  });
}
