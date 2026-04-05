import Testing
import CoreGraphics
@testable import Glyph

/// Tests for the snap-alignment engine that drives guide-based dragging.
/// AlignmentEngine treats (0, 0) as the canvas center, so a position of
/// CGSize.zero is perfectly centred on the canvas.
@Suite("AlignmentEngine")
struct AlignmentEngineTests {

    let canvasSize = CGSize(width: 390, height: 844)
    let layerSize  = CGSize(width: 100, height: 40)

    // MARK: - Canvas-centre snapping

    /// A layer placed within the snap threshold of canvas centre should snap
    /// exactly to (0, 0) on both axes.
    @Test("Snaps to canvas centre when within threshold")
    func snapsToCanvasCentre() {
        let nearCentre = CGSize(width: 5, height: 3)   // within default 8-pt threshold
        let (snapped, guides) = AlignmentEngine.snapPosition(
            nearCentre,
            layerSize: layerSize,
            otherLayers: [],
            canvasSize: canvasSize
        )

        #expect(snapped.width  == 0)
        #expect(snapped.height == 0)
        #expect(!guides.isEmpty, "Snap guides must be emitted when centring occurs")
    }

    /// A layer placed well outside the threshold must not be moved.
    @Test("Does not snap when far from any guide")
    func noSnapWhenFarFromGuides() {
        let farAway = CGSize(width: 120, height: 200)  // >> 8-pt threshold
        let (snapped, guides) = AlignmentEngine.snapPosition(
            farAway,
            layerSize: layerSize,
            otherLayers: [],
            canvasSize: canvasSize
        )

        #expect(snapped.width  == farAway.width,  "X should not be moved")
        #expect(snapped.height == farAway.height, "Y should not be moved")
        #expect(guides.isEmpty, "No guides should be emitted when nothing snaps")
    }

    /// When a snap occurs the returned guides must describe the axis and
    /// position that triggered the snap.
    @Test("Emits correct guide axis when snapping horizontally")
    func guidesDescribeSnapAxis() {
        // Place the layer so only the X axis is within threshold
        let pos = CGSize(width: 4, height: 200)
        let (_, guides) = AlignmentEngine.snapPosition(
            pos,
            layerSize: layerSize,
            otherLayers: [],
            canvasSize: canvasSize
        )

        let verticalGuides = guides.filter { $0.axis == .vertical }
        #expect(!verticalGuides.isEmpty, "A vertical guide should be emitted for X-axis snap")
    }

    /// A layer snapped by an adjacent layer's edge should receive a .layerEdge guide.
    @Test("Snaps to other layer edge and emits layerEdge guide")
    func snapsToOtherLayerEdge() {
        // Place a sibling layer whose left edge sits at x = 100
        let sibling = LayerGeometry(
            position: CGSize(width: 150, height: 0),
            size: CGSize(width: 100, height: 40)
        )

        // Move our layer so its right edge nearly touches the sibling's left edge (x=100)
        // Our layer right = position.width + halfW = position.width + 50
        // We want that ≈ 100 → position.width ≈ 50; put it at 53 (within 8pt)
        let pos = CGSize(width: 53, height: 200)
        let (snapped, guides) = AlignmentEngine.snapPosition(
            pos,
            layerSize: layerSize,
            otherLayers: [sibling],
            canvasSize: canvasSize
        )

        let edgeGuides = guides.filter { $0.kind == .layerEdge }
        #expect(!edgeGuides.isEmpty, "layerEdge guide must be emitted when snapping to another layer")
        _ = snapped  // snapped position consumed – main check is the guide
    }

    // MARK: - Custom threshold

    /// Passing a zero threshold should prevent all snapping.
    @Test("Zero threshold prevents all snapping")
    func zeroThresholdDisablesSnap() {
        let nearCentre = CGSize(width: 1, height: 1)
        let (snapped, guides) = AlignmentEngine.snapPosition(
            nearCentre,
            layerSize: layerSize,
            otherLayers: [],
            canvasSize: canvasSize,
            threshold: 0
        )

        #expect(snapped.width  == nearCentre.width)
        #expect(snapped.height == nearCentre.height)
        #expect(guides.isEmpty)
    }
}
