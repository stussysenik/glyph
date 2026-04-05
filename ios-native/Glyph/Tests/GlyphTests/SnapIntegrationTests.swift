import Testing
import SwiftUI
@testable import Glyph

@Suite("Snap Integration")
@MainActor
struct SnapIntegrationTests {

    @Test("updatePosition snaps to canvas center when within threshold")
    func snapsToCenter() {
        let vm = CanvasViewModel()
        vm.canvasSize = CGSize(width: 390, height: 844)
        vm.addTextLayer()
        let id = vm.selectedLayerID!

        // Position near center (within 8pt default threshold)
        vm.updatePosition(id: id, position: CGSize(width: 3, height: -2))

        let layer = vm.layers.first { $0.id == id }!
        #expect(layer.position.width == 0)
        #expect(layer.position.height == 0)
        #expect(!vm.activeGuides.isEmpty)
    }

    @Test("updatePosition does not snap when far from guides")
    func noSnapWhenFar() {
        let vm = CanvasViewModel()
        vm.canvasSize = CGSize(width: 390, height: 844)
        vm.addTextLayer()
        let id = vm.selectedLayerID!

        vm.updatePosition(id: id, position: CGSize(width: 100, height: 100))

        let layer = vm.layers.first { $0.id == id }!
        #expect(layer.position.width == 100)
        #expect(layer.position.height == 100)
        #expect(vm.activeGuides.isEmpty)
    }

    @Test("updatePosition snaps to other layer edge")
    func snapsToOtherLayer() {
        let vm = CanvasViewModel()
        vm.canvasSize = CGSize(width: 390, height: 844)

        // Add first layer at a known position
        vm.addTextLayer()
        let id1 = vm.selectedLayerID!
        vm.updatePosition(id: id1, position: CGSize(width: 0, height: 0))
        vm.clearActiveGuides()

        // Add second layer near the first
        vm.addTextLayer()
        let id2 = vm.selectedLayerID!
        vm.updatePosition(id: id2, position: CGSize(width: 3, height: 50))

        // Should snap X to 0 (aligned with first layer's center)
        let layer2 = vm.layers.first { $0.id == id2 }!
        #expect(layer2.position.width == 0)
    }

    @Test("deselectAll clears active guides")
    func deselectClearsGuides() {
        let vm = CanvasViewModel()
        vm.canvasSize = CGSize(width: 390, height: 844)
        vm.addTextLayer()
        let id = vm.selectedLayerID!

        vm.updatePosition(id: id, position: CGSize(width: 3, height: -2))
        #expect(!vm.activeGuides.isEmpty)

        vm.deselectAll()
        #expect(vm.activeGuides.isEmpty)
    }

    @Test("custom snapThreshold is respected")
    func customThreshold() {
        let vm = CanvasViewModel()
        vm.canvasSize = CGSize(width: 390, height: 844)
        vm.snapThreshold = 2.0  // Very tight threshold
        vm.addTextLayer()
        let id = vm.selectedLayerID!

        // 5pt from center — should NOT snap with 2pt threshold
        vm.updatePosition(id: id, position: CGSize(width: 5, height: 5))

        let layer = vm.layers.first { $0.id == id }!
        #expect(layer.position.width == 5)
        #expect(layer.position.height == 5)
    }
}
