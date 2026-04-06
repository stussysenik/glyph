import Testing
import SwiftUI
import UIKit
@testable import Glyph

@Suite("Undo Stack")
struct UndoStackTests {

    // MARK: - Initial state

    @Test("fresh view model has empty undo/redo stacks")
    func initialState() {
        let vm = CanvasViewModel()
        #expect(!vm.canUndo)
        #expect(!vm.canRedo)
    }

    // MARK: - Push via mutation

    @Test("adding a text layer enables undo")
    func addTextEnablesUndo() {
        let vm = CanvasViewModel()
        vm.addTextLayer()
        #expect(vm.canUndo)
        #expect(!vm.canRedo)
    }

    @Test("adding an image layer enables undo")
    func addImageEnablesUndo() {
        let vm = CanvasViewModel()
        let img = UIImage(systemName: "star")!
        vm.addImageLayer(img)
        #expect(vm.canUndo)
    }

    // MARK: - Undo restores state

    @Test("undo after addTextLayer removes the layer")
    func undoAddText() {
        let vm = CanvasViewModel()
        vm.addTextLayer()
        #expect(vm.layers.count == 1)

        vm.undo()
        #expect(vm.layers.isEmpty)
        #expect(vm.selectedLayerID == nil)
    }

    @Test("undo after addImageLayer removes the layer")
    func undoAddImage() {
        let vm = CanvasViewModel()
        vm.addImageLayer(UIImage(systemName: "star")!)
        #expect(vm.layers.count == 1)

        vm.undo()
        #expect(vm.layers.isEmpty)
    }

    @Test("undo restores selected layer ID")
    func undoRestoresSelection() {
        let vm = CanvasViewModel()
        vm.addTextLayer()
        let id = vm.layers.first!.id
        vm.addTextLayer()
        #expect(vm.selectedLayerID != id)

        vm.undo()
        #expect(vm.selectedLayerID == id)
    }

    @Test("undo clears isEditing")
    func undoClearsEditing() {
        let vm = CanvasViewModel()
        vm.addTextLayer()
        #expect(vm.isEditing)

        vm.undo()
        #expect(!vm.isEditing)
    }

    // MARK: - Redo

    @Test("redo after undo restores the undone state")
    func redoRestores() {
        let vm = CanvasViewModel()
        vm.addTextLayer()
        let id = vm.layers.first!.id

        vm.undo()
        #expect(vm.layers.isEmpty)
        #expect(vm.canRedo)

        vm.redo()
        #expect(vm.layers.count == 1)
        #expect(vm.layers.first!.id == id)
        #expect(!vm.canRedo)
    }

    @Test("redo after multiple undos restores the last undone state")
    func redoAfterMultipleUndo() {
        let vm = CanvasViewModel()
        vm.addTextLayer()
        vm.addTextLayer()
        vm.addTextLayer()
        #expect(vm.layers.count == 3)

        vm.undo()
        vm.undo()
        #expect(vm.layers.count == 1)
        #expect(vm.canRedo)

        vm.redo()
        #expect(vm.layers.count == 2)
    }

    // MARK: - New mutation clears redo stack

    @Test("new mutation after undo clears redo stack")
    func newMutationClearsRedo() {
        let vm = CanvasViewModel()
        vm.addTextLayer()
        vm.addTextLayer()
        vm.undo()
        #expect(vm.canRedo)

        vm.addTextLayer() // new mutation
        #expect(!vm.canRedo)
    }

    // MARK: - Boundary: undo/redo on empty stacks

    @Test("undo on empty stack is a no-op")
    func undoEmptyNoOp() {
        let vm = CanvasViewModel()
        vm.undo()
        #expect(vm.layers.isEmpty)
        #expect(!vm.canUndo)
    }

    @Test("redo on empty stack is a no-op")
    func redoEmptyNoOp() {
        let vm = CanvasViewModel()
        vm.redo()
        #expect(vm.layers.isEmpty)
        #expect(!vm.canRedo)
    }

    // MARK: - Stack overflow at 50

    @Test("undo stack caps at 50 states")
    func stackOverflow() {
        let vm = CanvasViewModel()
        // Push 55 states
        for i in 0..<55 {
            vm.addTextLayer(fontFamily: "Layer\(i)")
        }
        #expect(vm.layers.count == 55)

        // Should be able to undo 50 times (states 1..50 survive)
        var undone = 0
        while vm.canUndo {
            vm.undo()
            undone += 1
        }
        #expect(undone == 50)
        // 5 oldest states were dropped, so we should have 5 layers left
        #expect(vm.layers.count == 5)
    }

    // MARK: - Position undo

    @Test("undo restores layer position")
    func undoPosition() {
        let vm = CanvasViewModel()
        vm.canvasSize = CGSize(width: 400, height: 800)
        vm.addTextLayer()
        let id = vm.layers.first!.id

        vm.updatePosition(id: id, position: CGSize(width: 100, height: 200))
        vm.undo()

        let layer = vm.layers.first!
        // Position should be back to .zero (the state before updatePosition)
        #expect(layer.position.width == 0)
        #expect(layer.position.height == 0)
    }

    // MARK: - Rotation undo

    @Test("undo restores rotation")
    func undoRotation() {
        let vm = CanvasViewModel()
        vm.addTextLayer()
        let id = vm.layers.first!.id

        vm.updateRotation(id: id, rotation: .degrees(90))
        vm.undo()

        #expect(vm.layers.first!.rotation == .zero)
    }

    // MARK: - Scale undo

    @Test("undo restores scale")
    func undoScale() {
        let vm = CanvasViewModel()
        vm.addTextLayer()
        let id = vm.layers.first!.id

        vm.updateScale(id: id, scale: 2.5)
        vm.undo()

        #expect(vm.layers.first!.scale == 1.0)
    }

    // MARK: - Text content undo

    @Test("undo restores text content")
    func undoText() {
        let vm = CanvasViewModel()
        vm.addTextLayer()
        let id = vm.layers.first!.id

        vm.updateText(id: id, text: "Hello world")
        vm.undo()

        #expect((vm.layers.first as? TextLayer)?.text == "Tap to edit")
    }

    // MARK: - Color undo

    @Test("undo restores text color")
    func undoColor() {
        let vm = CanvasViewModel()
        vm.addTextLayer()
        let id = vm.layers.first!.id

        vm.updateColor(id: id, color: .red)
        vm.undo()

        let layer = vm.layers.first as? TextLayer
        #expect(layer?.textColor != .red)
    }

    // MARK: - Background undo

    @Test("undo restores background state")
    func undoBackground() {
        let vm = CanvasViewModel()
        let img = UIImage(systemName: "star")!

        vm.setBackground(img)
        #expect(vm.background != nil)

        vm.undo()
        #expect(vm.background == nil)
    }

    @Test("undo restores cleared background")
    func undoClearBackground() {
        let vm = CanvasViewModel()
        vm.setBackground(UIImage(systemName: "star")!)
        vm.clearBackground()
        #expect(vm.background == nil)

        vm.undo()
        #expect(vm.background != nil)
    }

    // MARK: - Lock/visibility undo

    @Test("undo restores lock state")
    func undoLock() {
        let vm = CanvasViewModel()
        vm.addTextLayer()
        let id = vm.layers.first!.id

        vm.toggleLock(id: id)
        #expect(vm.layers.first!.isLocked)

        vm.undo()
        #expect(!vm.layers.first!.isLocked)
    }

    @Test("undo restores visibility")
    func undoVisibility() {
        let vm = CanvasViewModel()
        vm.addTextLayer()
        let id = vm.layers.first!.id

        vm.toggleVisibility(id: id)
        #expect(!vm.layers.first!.isVisible)

        vm.undo()
        #expect(vm.layers.first!.isVisible)
    }

    // MARK: - Full round-trip

    @Test("undo then redo round-trip preserves all state")
    func fullRoundTrip() {
        let vm = CanvasViewModel()
        vm.canvasSize = CGSize(width: 400, height: 800)
        vm.addTextLayer()
        let id = vm.layers.first!.id

        vm.updateText(id: id, text: "Modified")
        vm.updateFontSize(id: id, fontSize: 100)
        vm.updateRotation(id: id, rotation: .degrees(45))

        let textBeforeUndo = (vm.layers.first as? TextLayer)?.text
        let fontSizeBefore = (vm.layers.first as? TextLayer)?.fontSize
        let rotationBefore = vm.layers.first!.rotation

        // Undo all 3
        vm.undo()
        vm.undo()
        vm.undo()

        // Redo all 3
        vm.redo()
        vm.redo()
        vm.redo()

        #expect((vm.layers.first as? TextLayer)?.text == textBeforeUndo)
        #expect((vm.layers.first as? TextLayer)?.fontSize == fontSizeBefore)
        #expect(vm.layers.first!.rotation == rotationBefore)
    }
}
