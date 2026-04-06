import Testing
import SwiftUI
import UIKit
@testable import Glyph

@Suite("Custom Guides")
struct CustomGuideTests {

    // MARK: - Add

    @Test("addCustomGuide creates a guide with correct axis and position")
    func addGuide() {
        let vm = CanvasViewModel()
        vm.addCustomGuide(axis: .vertical, position: 50)
        vm.addCustomGuide(axis: .horizontal, position: -30)

        #expect(vm.customGuides.count == 2)
        #expect(vm.customGuides[0].axis == .vertical)
        #expect(vm.customGuides[0].position == 50)
        #expect(vm.customGuides[1].axis == .horizontal)
        #expect(vm.customGuides[1].position == -30)
    }

    @Test("each guide gets a unique ID")
    func uniqueIDs() {
        let vm = CanvasViewModel()
        vm.addCustomGuide(axis: .vertical, position: 10)
        vm.addCustomGuide(axis: .vertical, position: 20)

        #expect(vm.customGuides[0].id != vm.customGuides[1].id)
    }

    // MARK: - Remove

    @Test("removeCustomGuide removes by ID")
    func removeGuide() {
        let vm = CanvasViewModel()
        vm.addCustomGuide(axis: .vertical, position: 50)
        vm.addCustomGuide(axis: .horizontal, position: 100)
        let targetID = vm.customGuides[0].id

        vm.removeCustomGuide(id: targetID)

        #expect(vm.customGuides.count == 1)
        #expect(vm.customGuides[0].axis == .horizontal)
    }

    @Test("removeCustomGuide with unknown ID is a no-op")
    func removeUnknownID() {
        let vm = CanvasViewModel()
        vm.addCustomGuide(axis: .vertical, position: 50)
        vm.removeCustomGuide(id: UUID())

        #expect(vm.customGuides.count == 1)
    }

    @Test("remove all guides leaves empty array")
    func removeAll() {
        let vm = CanvasViewModel()
        vm.addCustomGuide(axis: .vertical, position: 10)
        vm.addCustomGuide(axis: .horizontal, position: 20)

        for guide in vm.customGuides {
            vm.removeCustomGuide(id: guide.id)
        }

        #expect(vm.customGuides.isEmpty)
    }

    // MARK: - Move

    @Test("moveCustomGuide updates position")
    func moveGuide() {
        let vm = CanvasViewModel()
        vm.addCustomGuide(axis: .vertical, position: 50)
        let id = vm.customGuides[0].id

        vm.moveCustomGuide(id: id, to: 75)

        #expect(vm.customGuides[0].position == 75)
        #expect(vm.customGuides[0].axis == .vertical)
    }

    @Test("moveCustomGuide with unknown ID is a no-op")
    func moveUnknownID() {
        let vm = CanvasViewModel()
        vm.addCustomGuide(axis: .vertical, position: 50)

        vm.moveCustomGuide(id: UUID(), to: 200)

        #expect(vm.customGuides[0].position == 50)
    }

    // MARK: - Snap Integration

    @Test("layer snaps to vertical custom guide within threshold")
    func snapToVerticalGuide() {
        let vm = CanvasViewModel()
        vm.canvasSize = CGSize(width: 400, height: 800)
        vm.snapThreshold = 8

        // Place a vertical guide at x=100 (offset from center)
        vm.addCustomGuide(axis: .vertical, position: 100)

        // Add a layer and move it close to the guide (x=96, within 8pt threshold)
        vm.addTextLayer()
        let id = vm.layers.first!.id
        vm.updatePosition(id: id, position: CGSize(width: 96, height: 0))

        // Layer should snap to x=100
        #expect(abs(vm.layers.first!.position.width - 100) < 0.5)
    }

    @Test("layer snaps to horizontal custom guide within threshold")
    func snapToHorizontalGuide() {
        let vm = CanvasViewModel()
        vm.canvasSize = CGSize(width: 400, height: 800)
        vm.snapThreshold = 8

        vm.addCustomGuide(axis: .horizontal, position: -50)

        vm.addTextLayer()
        let id = vm.layers.first!.id
        vm.updatePosition(id: id, position: CGSize(width: 0, height: -47))

        #expect(abs(vm.layers.first!.position.height - (-50)) < 0.5)
    }

    @Test("layer does not snap to custom guide beyond threshold")
    func noSnapBeyondThreshold() {
        let vm = CanvasViewModel()
        vm.canvasSize = CGSize(width: 400, height: 800)
        vm.snapThreshold = 8

        vm.addCustomGuide(axis: .vertical, position: 100)

        vm.addTextLayer()
        let id = vm.layers.first!.id
        // 20pt away — well beyond 8pt threshold
        vm.updatePosition(id: id, position: CGSize(width: 80, height: 0))

        #expect(vm.layers.first!.position.width == 80)
    }

    @Test("layer snaps to closest of multiple custom guides")
    func snapToClosestGuide() {
        let vm = CanvasViewModel()
        vm.canvasSize = CGSize(width: 400, height: 800)
        vm.snapThreshold = 10

        // Two vertical guides at x=50 and x=100
        vm.addCustomGuide(axis: .vertical, position: 50)
        vm.addCustomGuide(axis: .vertical, position: 100)

        vm.addTextLayer()
        let id = vm.layers.first!.id
        // At x=97 — within threshold of x=100, not within threshold of x=50
        vm.updatePosition(id: id, position: CGSize(width: 97, height: 0))

        #expect(abs(vm.layers.first!.position.width - 100) < 0.5)
    }

    @Test("custom guides produce active guides on snap")
    func customGuideProducesActiveGuide() {
        let vm = CanvasViewModel()
        vm.canvasSize = CGSize(width: 400, height: 800)
        vm.snapThreshold = 10

        vm.addCustomGuide(axis: .vertical, position: 60)

        vm.addTextLayer()
        let id = vm.layers.first!.id
        vm.updatePosition(id: id, position: CGSize(width: 55, height: 0))

        // Should have at least one active guide from the custom guide snap
        let hasVerticalGuide = vm.activeGuides.contains { $0.axis == .vertical && abs($0.position - 60) < 0.5 }
        #expect(hasVerticalGuide)
    }

    // MARK: - Snap threshold sensitivity

    @Test("narrow threshold requires closer proximity")
    func narrowThreshold() {
        let vm = CanvasViewModel()
        vm.canvasSize = CGSize(width: 400, height: 800)
        vm.snapThreshold = 2

        vm.addCustomGuide(axis: .vertical, position: 100)

        vm.addTextLayer()
        let id = vm.layers.first!.id
        // 5pt away — beyond 2pt threshold
        vm.updatePosition(id: id, position: CGSize(width: 95, height: 0))

        #expect(vm.layers.first!.position.width == 95)
    }

    @Test("wide threshold catches further layers")
    func wideThreshold() {
        let vm = CanvasViewModel()
        vm.canvasSize = CGSize(width: 400, height: 800)
        vm.snapThreshold = 20

        vm.addCustomGuide(axis: .vertical, position: 100)

        vm.addTextLayer()
        let id = vm.layers.first!.id
        // 15pt away — within 20pt threshold
        vm.updatePosition(id: id, position: CGSize(width: 85, height: 0))

        #expect(abs(vm.layers.first!.position.width - 100) < 0.5)
    }

    // MARK: - Guides at zero (center)

    @Test("custom guide at position 0 (canvas center)")
    func guideAtCenter() {
        let vm = CanvasViewModel()
        vm.canvasSize = CGSize(width: 400, height: 800)
        vm.snapThreshold = 8

        vm.addCustomGuide(axis: .vertical, position: 0)

        vm.addTextLayer()
        let id = vm.layers.first!.id
        vm.updatePosition(id: id, position: CGSize(width: 3, height: 0))

        #expect(abs(vm.layers.first!.position.width) < 0.5)
    }

    // MARK: - Interplay with built-in snap

    @Test("custom guide snaps alongside canvas center snap")
    func customPlusBuiltinSnap() {
        let vm = CanvasViewModel()
        vm.canvasSize = CGSize(width: 400, height: 800)
        vm.snapThreshold = 10

        // Horizontal custom guide at y=100
        vm.addCustomGuide(axis: .horizontal, position: 100)

        vm.addTextLayer()
        let id = vm.layers.first!.id
        // Near center x (0) and near custom guide y (100)
        vm.updatePosition(id: id, position: CGSize(width: 3, height: 97))

        // Should snap to x=0 (canvas center) and y=100 (custom guide)
        #expect(abs(vm.layers.first!.position.width) < 0.5)
        #expect(abs(vm.layers.first!.position.height - 100) < 0.5)
    }
}
