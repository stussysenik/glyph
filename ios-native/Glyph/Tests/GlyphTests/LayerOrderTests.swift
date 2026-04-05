import Testing
import SwiftUI
@testable import Glyph

/// Tests for CanvasViewModel layer CRUD, z-index management, and ordering.
/// CanvasViewModel is @Observable (not an actor), so tests run on the main
/// actor to match the expected mutation context.
@Suite("Layer Order & CRUD")
@MainActor
struct LayerOrderTests {

    // MARK: - Add layers

    @Test("Adding text layers assigns ascending z-indices")
    func addLayersAscendingZIndex() {
        let vm = CanvasViewModel()
        vm.addTextLayer()
        vm.addTextLayer()
        vm.addTextLayer()

        #expect(vm.layers.count == 3)
        let zIndices = vm.layers.map(\.zIndex)
        #expect(zIndices == zIndices.sorted(), "z-indices must be monotonically ascending after add")
    }

    @Test("First added layer gets z-index 0")
    func firstLayerZIndexIsZero() {
        let vm = CanvasViewModel()
        vm.addTextLayer()
        #expect(vm.layers[0].zIndex == 0)
    }

    @Test("Adding a layer selects it")
    func addLayerSelectsIt() {
        let vm = CanvasViewModel()
        vm.addTextLayer()
        let id = try? #require(vm.layers.first?.id)
        #expect(vm.selectedLayerID == id)
    }

    // MARK: - Remove layers

    @Test("Removing a layer by ID leaves the rest intact")
    func removeLayerById() {
        let vm = CanvasViewModel()
        vm.addTextLayer()
        vm.addTextLayer()

        let firstID = try? #require(vm.layers.first?.id)
        if let idToRemove = firstID {
            vm.removeLayer(id: idToRemove)
        }

        #expect(vm.layers.count == 1)
        let remaining = vm.layers.map(\.id)
        #expect(!remaining.contains(firstID ?? UUID()), "Removed layer ID must not appear in layers")
    }

    @Test("Removing selected layer clears selection")
    func removeSelectedLayerClearsSelection() {
        let vm = CanvasViewModel()
        vm.addTextLayer()
        let id = vm.layers[0].id
        vm.selectedLayerID = id
        vm.removeLayer(id: id)
        #expect(vm.selectedLayerID == nil)
    }

    @Test("Z-indices are renumbered after removal")
    func zIndicesRenumberedAfterRemoval() {
        let vm = CanvasViewModel()
        vm.addTextLayer()
        vm.addTextLayer()
        vm.addTextLayer()

        let idToRemove = vm.layers[1].id
        vm.removeLayer(id: idToRemove)

        // After removing the middle layer, z-indices should be 0, 1
        let zIndices = vm.layers.map(\.zIndex).sorted()
        #expect(zIndices == [0, 1])
    }

    // MARK: - Move (reorder) layers

    @Test("Moving a layer updates z-indices correctly")
    func moveLayerUpdatesZIndices() {
        let vm = CanvasViewModel()
        vm.addTextLayer()
        vm.addTextLayer()
        vm.addTextLayer()

        // Move last layer to index 0
        vm.moveLayer(from: IndexSet(integer: 2), to: 0)

        let zIndices = vm.layers.map(\.zIndex)
        #expect(zIndices == [0, 1, 2], "After move, z-indices must be re-assigned 0...n-1")
    }

    // MARK: - sortedLayers computed property

    @Test("sortedLayers returns layers ordered by ascending zIndex")
    func sortedLayersOrder() {
        let vm = CanvasViewModel()
        vm.addTextLayer()
        vm.addTextLayer()
        vm.addTextLayer()

        // Manually shuffle the internal array
        vm.layers.reverse()

        let sorted = vm.sortedLayers.map(\.zIndex)
        #expect(sorted == sorted.sorted())
    }

    // MARK: - Visibility & lock

    @Test("Toggle visibility flips isVisible")
    func toggleVisibilityFlips() {
        let vm = CanvasViewModel()
        vm.addTextLayer()
        let id = vm.layers[0].id
        let initial = vm.layers[0].isVisible

        vm.toggleVisibility(id: id)
        #expect(vm.layers[0].isVisible == !initial)

        vm.toggleVisibility(id: id)
        #expect(vm.layers[0].isVisible == initial)
    }

    @Test("Toggle lock flips isLocked")
    func toggleLockFlips() {
        let vm = CanvasViewModel()
        vm.addTextLayer()
        let id = vm.layers[0].id
        #expect(vm.layers[0].isLocked == false)

        vm.toggleLock(id: id)
        #expect(vm.layers[0].isLocked == true)
    }
}
