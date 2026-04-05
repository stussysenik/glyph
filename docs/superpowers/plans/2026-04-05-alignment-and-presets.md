# Alignment & Style Presets — Implementation Plan

> **For agentic workers:** Use superpowers:subagent-driven-development or superpowers:executing-plans.

**Goal:** Add a smart alignment/snap system with visual guides and a style preset library to the Glyph canvas, enabling pixel-precise layout and one-tap style reuse across text layers.

**Architecture:** The alignment engine is a pure, UI-free function that computes snapped positions and guide lines from layer geometry — it lives in a dedicated `AlignmentEngine.swift` and can be unit-tested in isolation. Guide rendering is handled by a lightweight `GuidesOverlayView` layered above the canvas content but below the toolbar. Presets are `Codable` structs persisted as JSON in the app's Documents directory, managed by a single `PresetStore` observable that any view can read.

**Tech Stack:** SwiftUI, UIImpactFeedbackGenerator, Codable/JSON, FileManager

---

## File Map

| Action | Path | Purpose |
|--------|------|---------|
| Create | `Sources/Models/Guide.swift` | Guide value types (line, snap threshold) |
| Create | `Sources/Engine/AlignmentEngine.swift` | Pure snap/guide computation function |
| Create | `Sources/Views/GuidesOverlayView.swift` | Canvas overlay that draws active guides + grid + rulers |
| Modify | `Sources/ViewModels/CanvasViewModel.swift` | Add guide state, snap toggle, axis-constraint flag |
| Modify | `Sources/Views/CanvasView.swift` | Wire GuidesOverlayView, guide toolbar button, two-finger constraint gesture |
| Modify | `Sources/Views/TextOverlayView.swift` | Call AlignmentEngine during drag, trigger haptic on snap |
| Create | `Sources/Models/StylePreset.swift` | `StylePreset` Codable struct + built-in defaults |
| Create | `Sources/Store/PresetStore.swift` | @Observable JSON-backed preset persistence |
| Create | `Sources/Views/PresetSheetView.swift` | Bottom sheet: preset list + live preview + management actions |
| Create | `Sources/Views/PresetRowView.swift` | Single preset row with live text preview and swipe-to-delete |
| Modify | `Sources/Views/TextEditSheet.swift` | "Save Preset" button + "Apply Preset" entry point |

---

### Task 1: Guide Value Types
**Files:** Create: `ios-native/Glyph/Sources/Models/Guide.swift`

- [ ] **Step 1:** Define the `GuideAxis`, `GuideKind`, and `Guide` types used throughout the alignment system.

```swift
// Sources/Models/Guide.swift
import CoreGraphics

/// Which axis a guide line runs along.
enum GuideAxis: Sendable {
    case horizontal   // a horizontal line at a fixed Y
    case vertical     // a vertical line at a fixed X
}

/// What caused the guide to appear — used to pick tint in the overlay.
enum GuideKind: Sendable {
    case centerCanvas       // canvas center axis
    case layerEdge          // aligned with another layer's edge
    case equalSpacing       // equal distribution between layers
}

/// A single snap guide — a position value + metadata for rendering.
struct Guide: Identifiable, Sendable {
    let id: UUID
    let axis: GuideAxis
    /// Position along the axis' perpendicular dimension in canvas coordinates.
    let position: CGFloat
    let kind: GuideKind

    init(axis: GuideAxis, position: CGFloat, kind: GuideKind) {
        self.id = UUID()
        self.axis = axis
        self.position = position
        self.kind = kind
    }
}
```

- [ ] **Step 2:** Build the project to verify it compiles.

```bash
flowdeck build
```

---

### Task 2: Alignment Engine (Pure Function)
**Files:** Create: `ios-native/Glyph/Sources/Engine/AlignmentEngine.swift`

- [ ] **Step 1:** Create the directory and file, then write the snap engine as a pure, testable namespace.

```swift
// Sources/Engine/AlignmentEngine.swift
import CoreGraphics

/// Pure alignment math — no UIKit, no SwiftUI, fully testable.
enum AlignmentEngine {

    /// Snap threshold in points. A layer snaps when it's within this distance of a guide.
    static let defaultThreshold: CGFloat = 8

    // MARK: - Public API

    /// Compute a snapped position and the active guides to display.
    ///
    /// - Parameters:
    ///   - position: Current drag position (CGSize offset from canvas center).
    ///   - layerSize: Bounding size of the layer being dragged.
    ///   - otherLayers: Geometry of all OTHER layers (not the dragged one).
    ///   - canvasSize: Full canvas size in points.
    ///   - threshold: Snap activation distance in points.
    /// - Returns: The (possibly snapped) position and any active guide lines to render.
    static func snapPosition(
        _ position: CGSize,
        layerSize: CGSize,
        otherLayers: [LayerGeometry],
        canvasSize: CGSize,
        threshold: CGFloat = defaultThreshold
    ) -> (snapped: CGSize, guides: [Guide]) {

        var result = position
        var guides: [Guide] = []

        let halfW = layerSize.width / 2
        let halfH = layerSize.height / 2

        // Candidate X positions (left edge, center, right edge of dragged layer in canvas space)
        let layerLeft   = position.width - halfW
        let layerCenterX = position.width
        let layerRight  = position.width + halfW

        // Candidate Y positions
        let layerTop     = position.height - halfH
        let layerCenterY = position.height
        let layerBottom  = position.height + halfH

        // --- Canvas center guides ---
        let snapCenterX = snap(
            candidates: [layerLeft, layerCenterX, layerRight],
            offsets: [-halfW, 0, halfW],
            to: 0,
            current: position.width,
            threshold: threshold
        )
        if let (snapped, _) = snapCenterX {
            result.width = snapped
            guides.append(Guide(axis: .vertical, position: 0, kind: .centerCanvas))
        }

        let snapCenterY = snap(
            candidates: [layerTop, layerCenterY, layerBottom],
            offsets: [-halfH, 0, halfH],
            to: 0,
            current: position.height,
            threshold: threshold
        )
        if let (snapped, _) = snapCenterY {
            result.height = snapped
            guides.append(Guide(axis: .horizontal, position: 0, kind: .centerCanvas))
        }

        // --- Other layer edge guides ---
        for other in otherLayers {
            let targets: [(CGFloat, GuideAxis)] = [
                (other.minX, .vertical),
                (other.centerX, .vertical),
                (other.maxX, .vertical),
                (other.minY, .horizontal),
                (other.centerY, .horizontal),
                (other.maxY, .horizontal),
            ]

            for (target, axis) in targets {
                if axis == .vertical {
                    let snapX = snap(
                        candidates: [layerLeft, layerCenterX, layerRight],
                        offsets: [-halfW, 0, halfW],
                        to: target,
                        current: result.width,
                        threshold: threshold
                    )
                    if let (snapped, _) = snapX {
                        result.width = snapped
                        guides.append(Guide(axis: .vertical, position: target, kind: .layerEdge))
                    }
                } else {
                    let snapY = snap(
                        candidates: [layerTop, layerCenterY, layerBottom],
                        offsets: [-halfH, 0, halfH],
                        to: target,
                        current: result.height,
                        threshold: threshold
                    )
                    if let (snapped, _) = snapY {
                        result.height = snapped
                        guides.append(Guide(axis: .horizontal, position: target, kind: .layerEdge))
                    }
                }
            }
        }

        // Deduplicate guides by axis + position
        let deduped = Dictionary(grouping: guides) { "\($0.axis)-\($0.position)" }
            .compactMap { $0.value.first }
        return (result, deduped)
    }

    // MARK: - Private Helpers

    /// Try to snap one of `candidates` to `target`. Returns the corrected center position
    /// and the offset that was used if within threshold, otherwise nil.
    private static func snap(
        candidates: [CGFloat],
        offsets: [CGFloat],
        to target: CGFloat,
        current: CGFloat,
        threshold: CGFloat
    ) -> (snappedCenter: CGFloat, offset: CGFloat)? {
        for (candidate, offset) in zip(candidates, offsets) {
            if abs(candidate - target) <= threshold {
                return (target - offset, offset)
            }
        }
        return nil
    }
}

// MARK: - Layer Geometry Helper

/// Flat geometry snapshot of a layer — computed from position + size.
struct LayerGeometry: Sendable {
    let minX, centerX, maxX: CGFloat
    let minY, centerY, maxY: CGFloat

    init(position: CGSize, size: CGSize) {
        let hw = size.width / 2
        let hh = size.height / 2
        minX = position.width - hw
        centerX = position.width
        maxX = position.width + hw
        minY = position.height - hh
        centerY = position.height
        maxY = position.height + hh
    }
}
```

- [ ] **Step 2:** Build the project.

```bash
flowdeck build
```

---

### Task 3: Guide State in CanvasViewModel
**Files:** Modify: `ios-native/Glyph/Sources/ViewModels/CanvasViewModel.swift`

- [ ] **Step 1:** Add guide-related state properties to `CanvasViewModel`.

```swift
// Add inside CanvasViewModel (@Observable class):

/// Whether the guide overlay (grid + snap lines) is visible.
var showGuides: Bool = false

/// Whether the rule-of-thirds grid is drawn (vs. the 8×14 grid).
var useRuleOfThirds: Bool = false

/// Active snap guides computed during a drag — cleared on drag end.
var activeGuides: [Guide] = []

/// When true, layer movement is constrained to horizontal or vertical axis.
var axisConstrained: Bool = false

/// The dominant axis when axisConstrained is true. Nil until direction is determined.
var constrainedAxis: GuideAxis? = nil
```

- [ ] **Step 2:** Add a method to update guides during a drag and clear them after.

```swift
// Add inside CanvasViewModel:

func updateActiveGuides(_ guides: [Guide]) {
    activeGuides = guides
}

func clearActiveGuides() {
    activeGuides = []
    constrainedAxis = nil
}
```

- [ ] **Step 3:** Build.

```bash
flowdeck build
```

---

### Task 4: Guides Overlay View
**Files:** Create: `ios-native/Glyph/Sources/Views/GuidesOverlayView.swift`

- [ ] **Step 1:** Build the overlay that renders the grid and active snap guides.

```swift
// Sources/Views/GuidesOverlayView.swift
import SwiftUI

private typealias DS = GlyphDesignSystem

struct GuidesOverlayView: View {
    let canvasSize: CGSize
    let showGrid: Bool
    let useRuleOfThirds: Bool
    let activeGuides: [Guide]

    // Grid color — very subtle
    private let gridColor = DS.Colors.textPrimary.opacity(0.06)
    private let guideColorCenter = DS.Colors.accent.opacity(0.75)
    private let guideColorEdge = Color.cyan.opacity(0.75)
    private let guideColorSpacing = Color.orange.opacity(0.75)
    private let lineWidth: CGFloat = 0.5
    private let guideLineWidth: CGFloat = 1

    var body: some View {
        ZStack {
            if showGrid {
                gridLines
            }
            activeGuideLines
        }
        .allowsHitTesting(false) // never intercept touches
    }

    // MARK: Grid

    @ViewBuilder
    private var gridLines: some View {
        Canvas { ctx, size in
            if useRuleOfThirds {
                drawRuleOfThirds(ctx: ctx, size: size)
            } else {
                drawEvenGrid(ctx: ctx, size: size)
            }
        }
    }

    private func drawRuleOfThirds(ctx: GraphicsContext, size: CGSize) {
        var path = Path()
        for i in 1...2 {
            let x = size.width * CGFloat(i) / 3
            let y = size.height * CGFloat(i) / 3
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: size.height))
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: size.width, y: y))
        }
        ctx.stroke(path, with: .color(gridColor), lineWidth: lineWidth)
    }

    private func drawEvenGrid(ctx: GraphicsContext, size: CGSize) {
        let cols = 8
        let rows = 14
        var path = Path()
        for col in 1..<cols {
            let x = size.width * CGFloat(col) / CGFloat(cols)
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: size.height))
        }
        for row in 1..<rows {
            let y = size.height * CGFloat(row) / CGFloat(rows)
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: size.width, y: y))
        }
        ctx.stroke(path, with: .color(gridColor), lineWidth: lineWidth)
    }

    // MARK: Snap Guides

    @ViewBuilder
    private var activeGuideLines: some View {
        Canvas { ctx, size in
            let originX = size.width / 2
            let originY = size.height / 2

            for guide in activeGuides {
                let color: Color = switch guide.kind {
                case .centerCanvas: guideColorCenter
                case .layerEdge:    guideColorEdge
                case .equalSpacing: guideColorSpacing
                }

                var path = Path()
                switch guide.axis {
                case .vertical:
                    let x = originX + guide.position
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: size.height))
                case .horizontal:
                    let y = originY + guide.position
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                }
                ctx.stroke(path, with: .color(color), lineWidth: guideLineWidth)
            }
        }
    }
}
```

- [ ] **Step 2:** Build.

```bash
flowdeck build
```

---

### Task 5: Wire Snap Into TextOverlayView
**Files:** Modify: `ios-native/Glyph/Sources/Views/TextOverlayView.swift`

- [ ] **Step 1:** Add a `snapEnabled` parameter and call `AlignmentEngine.snapPosition` during drag. Trigger haptic on each new snap.

```swift
// Add near the top of the TextOverlayView struct (new properties/dependencies):
let snapEnabled: Bool
let canvasSize: CGSize
let otherLayerGeometries: [LayerGeometry]
var onGuidesChanged: ([Guide]) -> Void
var onDragEnded: () -> Void

// Inside TextOverlayView — replace/augment the existing DragGesture handler:

private let haptic = UIImpactFeedbackGenerator(style: .light)

// In the drag .onChanged handler, after computing the new offset:
private func handleDragChanged(value: DragGesture.Value, overlay: TextOverlay) {
    var newOffset = CGSize(
        width: overlay.position.width + value.translation.width - lastTranslation.width,
        height: overlay.position.height + value.translation.height - lastTranslation.height
    )
    lastTranslation = value.translation

    // Apply axis constraint if active
    if axisConstrained {
        if constrainedAxis == .horizontal {
            newOffset.height = overlay.position.height
        } else {
            newOffset.width = overlay.position.width
        }
    }

    if snapEnabled {
        let layerSize = CGSize(width: 200, height: 60) // approximate; replace with measured size
        let (snapped, guides) = AlignmentEngine.snapPosition(
            newOffset,
            layerSize: layerSize,
            otherLayers: otherLayerGeometries,
            canvasSize: canvasSize
        )
        // Haptic only fires when a new snap engages
        if guides.count > activeGuidesCount {
            haptic.impactOccurred()
        }
        activeGuidesCount = guides.count
        onGuidesChanged(guides)
        viewModel.updatePosition(id: overlay.id, position: snapped)
    } else {
        onGuidesChanged([])
        viewModel.updatePosition(id: overlay.id, position: newOffset)
    }
}

// In .onEnded:
private func handleDragEnded() {
    lastTranslation = .zero
    activeGuidesCount = 0
    onDragEnded()
}
```

- [ ] **Step 2:** Add `@State private var activeGuidesCount: Int = 0` and `@State private var lastTranslation: CGSize = .zero` state vars alongside existing state.

- [ ] **Step 3:** Build.

```bash
flowdeck build
```

---

### Task 6: Wire Guides Into CanvasView
**Files:** Modify: `ios-native/Glyph/Sources/Views/CanvasView.swift`

- [ ] **Step 1:** Insert `GuidesOverlayView` inside the canvas `ZStack`, above the layer `ForEach` but below the toolbar.

```swift
// Inside the canvas ZStack, after the ForEach of layer overlays:
if viewModel.showGuides || !viewModel.activeGuides.isEmpty {
    GuidesOverlayView(
        canvasSize: canvasSize,
        showGrid: viewModel.showGuides,
        useRuleOfThirds: viewModel.useRuleOfThirds,
        activeGuides: viewModel.activeGuides
    )
    .frame(width: canvasSize.width, height: canvasSize.height)
}
```

- [ ] **Step 2:** Add the guides toggle button to the toolbar.

```swift
// Inside the toolbar HStack:
Button {
    viewModel.showGuides.toggle()
} label: {
    Image(systemName: viewModel.showGuides ? "grid.circle.fill" : "grid.circle")
        .font(.system(size: DS.Typography.body, weight: .medium))
        .foregroundStyle(viewModel.showGuides ? DS.Colors.accent : DS.Colors.textSecondary)
}
.accessibilityLabel(viewModel.showGuides ? "Hide guides" : "Show guides")
```

- [ ] **Step 3:** Add the two-finger simultaneous gesture for axis constraint. Attach it to the canvas ZStack.

```swift
// Attach to canvas ZStack as a simultaneous gesture:
.simultaneousGesture(
    DragGesture(minimumDistance: 4)
        .simultaneously(with: LongPressGesture(minimumDuration: 0))
        .onChanged { _ in
            // Two-finger detection is handled by checking activeTouchCount via UIGestureRecognizer bridge
            // For now, use a two-finger DragGesture workaround:
        }
)
// Preferred approach — attach a UIGestureRecognizer coordinator to detect two-finger drags:
.overlay(
    TwoFingerConstraintGestureView(isActive: $viewModel.axisConstrained)
        .allowsHitTesting(false)
)
```

- [ ] **Step 4:** Create `TwoFingerConstraintGestureView` as a `UIViewRepresentable` that installs a `UIPanGestureRecognizer` requiring `minimumNumberOfTouches = 2`.

```swift
struct TwoFingerConstraintGestureView: UIViewRepresentable {
    @Binding var isActive: Bool

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        let pan = UIPanGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handlePan(_:))
        )
        pan.minimumNumberOfTouches = 2
        pan.maximumNumberOfTouches = 2
        view.addGestureRecognizer(pan)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(isActive: $isActive) }

    class Coordinator: NSObject {
        var isActive: Binding<Bool>
        init(isActive: Binding<Bool>) { self.isActive = isActive }

        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            switch gesture.state {
            case .began, .changed: isActive.wrappedValue = true
            default: isActive.wrappedValue = false
            }
        }
    }
}
```

- [ ] **Step 5:** Build and visually verify guides appear when dragging a layer near canvas center.

```bash
flowdeck build && flowdeck run
```

- [ ] **Step 6:** Commit task 3–6.

```bash
cd /Users/s3nik/Desktop/instagram-story-builder
git add ios-native/Glyph/Sources/Models/Guide.swift \
        ios-native/Glyph/Sources/Engine/AlignmentEngine.swift \
        ios-native/Glyph/Sources/Views/GuidesOverlayView.swift \
        ios-native/Glyph/Sources/Views/TextOverlayView.swift \
        ios-native/Glyph/Sources/Views/CanvasView.swift \
        ios-native/Glyph/Sources/ViewModels/CanvasViewModel.swift
git commit -m "feat: alignment engine, snap guides, and grid overlay"
```

---

### Task 7: StylePreset Model
**Files:** Create: `ios-native/Glyph/Sources/Models/StylePreset.swift`

- [ ] **Step 1:** Define the `StylePreset` `Codable` struct and the built-in defaults.

```swift
// Sources/Models/StylePreset.swift
import Foundation

/// A named collection of text style properties that can be applied to any text layer.
struct StylePreset: Identifiable, Codable, Sendable {
    var id: UUID
    var name: String
    var fontFamily: String
    var fontSize: CGFloat
    var textColor: CodableColor
    var letterSpacing: CGFloat
    var alignment: TextAlignment
    var isBuiltIn: Bool

    /// Apply this preset's style values to a `TextOverlay`.
    func apply(to overlay: inout TextOverlay) {
        overlay.fontFamily = fontFamily
        overlay.fontSize = fontSize
        overlay.textColor = textColor.color
        overlay.letterSpacing = letterSpacing
        overlay.alignment = alignment
    }
}

// MARK: - Built-in Presets

extension StylePreset {
    static let builtIns: [StylePreset] = [
        StylePreset(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            name: "Editorial Bold",
            fontFamily: "Georgia-Bold",
            fontSize: 28,
            textColor: CodableColor(.black),
            letterSpacing: 0,
            alignment: .leading,
            isBuiltIn: true
        ),
        StylePreset(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            name: "Caption Minimal",
            fontFamily: "Helvetica Neue",
            fontSize: 13,
            textColor: CodableColor(.init(white: 0.4, alpha: 1)),
            letterSpacing: 1.5,
            alignment: .center,
            isBuiltIn: true
        ),
        StylePreset(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
            name: "Display Statement",
            fontFamily: "Georgia",
            fontSize: 34,
            textColor: CodableColor(.black),
            letterSpacing: -0.5,
            alignment: .center,
            isBuiltIn: true
        ),
        StylePreset(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!,
            name: "Mono Label",
            fontFamily: "Courier New",
            fontSize: 11,
            textColor: CodableColor(.init(white: 0.3, alpha: 1)),
            letterSpacing: 2,
            alignment: .leading,
            isBuiltIn: true
        ),
        StylePreset(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000005")!,
            name: "Story Headline",
            fontFamily: "Georgia-BoldItalic",
            fontSize: 22,
            textColor: CodableColor(.white),
            letterSpacing: 0.3,
            alignment: .center,
            isBuiltIn: true
        ),
    ]
}

// MARK: - CodableColor

/// UIColor/Color wrapper that round-trips through JSON.
struct CodableColor: Codable, Sendable {
    var red: CGFloat
    var green: CGFloat
    var blue: CGFloat
    var alpha: CGFloat

    init(_ uiColor: UIColor) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        red = r; green = g; blue = b; alpha = a
    }

    var color: UIColor {
        UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
}
```

- [ ] **Step 2:** Build.

```bash
flowdeck build
```

---

### Task 8: PresetStore
**Files:** Create: `ios-native/Glyph/Sources/Store/PresetStore.swift`

- [ ] **Step 1:** Build the `@Observable` store that merges built-ins with user presets from disk.

```swift
// Sources/Store/PresetStore.swift
import Foundation
import Observation

@Observable
final class PresetStore {

    // Visible list: built-ins first, then user presets in their saved order
    private(set) var presets: [StylePreset] = []

    private let fileName = "style-presets.json"

    private var fileURL: URL {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
    }

    init() {
        load()
    }

    // MARK: - CRUD

    func save(preset: StylePreset) {
        var user = userPresets()
        if let idx = user.firstIndex(where: { $0.id == preset.id }) {
            user[idx] = preset
        } else {
            user.append(preset)
        }
        persist(user)
        reload()
    }

    func saveFromOverlay(_ overlay: TextOverlay, name: String) {
        let preset = StylePreset(
            id: UUID(),
            name: name,
            fontFamily: overlay.fontFamily,
            fontSize: overlay.fontSize,
            textColor: CodableColor(overlay.textColor),
            letterSpacing: overlay.letterSpacing,
            alignment: overlay.alignment,
            isBuiltIn: false
        )
        save(preset: preset)
    }

    func delete(preset: StylePreset) {
        guard !preset.isBuiltIn else { return }
        var user = userPresets()
        user.removeAll { $0.id == preset.id }
        persist(user)
        reload()
    }

    func rename(preset: StylePreset, to newName: String) {
        var updated = preset
        updated.name = newName
        save(preset: updated)
    }

    func move(fromOffsets source: IndexSet, toOffset destination: Int) {
        var user = userPresets()
        user.move(fromOffsets: source, toOffset: destination)
        persist(user)
        reload()
    }

    // MARK: - Persistence

    private func load() {
        reload()
    }

    private func reload() {
        presets = StylePreset.builtIns + userPresets()
    }

    private func userPresets() -> [StylePreset] {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([StylePreset].self, from: data) else {
            return []
        }
        return decoded.filter { !$0.isBuiltIn }
    }

    private func persist(_ userPresets: [StylePreset]) {
        guard let data = try? JSONEncoder().encode(userPresets) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
```

- [ ] **Step 2:** Inject `PresetStore` as an environment object from the app's root.

```swift
// In GlyphApp.swift (or root ContentView), add:
@State private var presetStore = PresetStore()

// In the WindowGroup body:
ContentView()
    .environment(presetStore)
```

- [ ] **Step 3:** Build.

```bash
flowdeck build
```

---

### Task 9: Preset Row View
**Files:** Create: `ios-native/Glyph/Sources/Views/PresetRowView.swift`

- [ ] **Step 1:** Build a single row with a live text preview rendering the preset's style.

```swift
// Sources/Views/PresetRowView.swift
import SwiftUI

private typealias DS = GlyphDesignSystem

struct PresetRowView: View {
    let preset: StylePreset
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: DS.Spacing.md) {
                // Live preview swatch
                Text("Aa")
                    .font(.custom(preset.fontFamily, size: 20))
                    .foregroundStyle(Color(preset.textColor.color))
                    .tracking(preset.letterSpacing)
                    .frame(width: 56, height: 44)
                    .background(DS.Colors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: DS.Radius.sm))

                VStack(alignment: .leading, spacing: 2) {
                    Text(preset.name)
                        .font(.system(size: DS.Typography.body, weight: .medium))
                        .foregroundStyle(DS.Colors.textPrimary)

                    Text("\(preset.fontFamily) · \(Int(preset.fontSize))pt")
                        .font(.system(size: DS.Typography.caption))
                        .foregroundStyle(DS.Colors.textSecondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: DS.Typography.body, weight: .semibold))
                        .foregroundStyle(DS.Colors.accent)
                }

                if preset.isBuiltIn {
                    Image(systemName: "star.fill")
                        .font(.system(size: DS.Typography.caption))
                        .foregroundStyle(DS.Colors.textSecondary.opacity(0.5))
                }
            }
            .padding(.horizontal, DS.Spacing.lg)
            .padding(.vertical, DS.Spacing.sm)
            .background(isSelected ? DS.Colors.accent.opacity(0.08) : .clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
```

- [ ] **Step 2:** Build.

```bash
flowdeck build
```

---

### Task 10: Preset Sheet View
**Files:** Create: `ios-native/Glyph/Sources/Views/PresetSheetView.swift`

- [ ] **Step 1:** Build the full bottom sheet with list, inline rename, and save/apply actions.

```swift
// Sources/Views/PresetSheetView.swift
import SwiftUI

private typealias DS = GlyphDesignSystem

struct PresetSheetView: View {
    @Environment(PresetStore.self) private var store
    @Environment(CanvasViewModel.self) private var viewModel

    @State private var newPresetName: String = ""
    @State private var isSaveFieldVisible: Bool = false
    @State private var renameTarget: StylePreset? = nil
    @State private var renameText: String = ""

    var selectedOverlay: TextOverlay? {
        guard let id = viewModel.selectedOverlayID else { return nil }
        return viewModel.overlays.first { $0.id == id }
    }

    var body: some View {
        NavigationStack {
            List {
                // Save current style section (shown only when a layer is selected)
                if let overlay = selectedOverlay {
                    Section("Save Current Style") {
                        if isSaveFieldVisible {
                            HStack {
                                TextField("Preset name", text: $newPresetName)
                                    .font(.system(size: DS.Typography.body))
                                Button("Save") {
                                    guard !newPresetName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                                    store.saveFromOverlay(overlay, name: newPresetName)
                                    newPresetName = ""
                                    isSaveFieldVisible = false
                                }
                                .font(.system(size: DS.Typography.body, weight: .semibold))
                                .foregroundStyle(DS.Colors.accent)
                            }
                        } else {
                            Button {
                                isSaveFieldVisible = true
                            } label: {
                                Label("Save as Preset…", systemImage: "plus.circle")
                                    .font(.system(size: DS.Typography.body))
                                    .foregroundStyle(DS.Colors.accent)
                            }
                        }
                    }
                }

                // Preset list
                Section("Presets") {
                    ForEach(store.presets) { preset in
                        PresetRowView(
                            preset: preset,
                            isSelected: false,
                            onTap: {
                                if var overlay = selectedOverlay {
                                    preset.apply(to: &overlay)
                                    viewModel.updateOverlay(overlay)
                                }
                            }
                        )
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            if !preset.isBuiltIn {
                                Button(role: .destructive) {
                                    store.delete(preset: preset)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }

                                Button {
                                    renameTarget = preset
                                    renameText = preset.name
                                } label: {
                                    Label("Rename", systemImage: "pencil")
                                }
                                .tint(DS.Colors.accent)
                            }
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowSeparatorTint(DS.Colors.surface)
                    }
                    .onMove { source, destination in
                        store.move(fromOffsets: source, toOffset: destination)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Style Presets")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    EditButton()
                        .font(.system(size: DS.Typography.body))
                }
            }
        }
        .alert("Rename Preset", isPresented: Binding(
            get: { renameTarget != nil },
            set: { if !$0 { renameTarget = nil } }
        )) {
            TextField("New name", text: $renameText)
            Button("Rename") {
                if let target = renameTarget {
                    store.rename(preset: target, to: renameText)
                }
                renameTarget = nil
            }
            Button("Cancel", role: .cancel) { renameTarget = nil }
        }
    }
}
```

- [ ] **Step 2:** Build.

```bash
flowdeck build
```

---

### Task 11: Expose Presets from TextEditSheet
**Files:** Modify: `ios-native/Glyph/Sources/Views/TextEditSheet.swift`

- [ ] **Step 1:** Add a "Presets" button in the text edit sheet toolbar that presents `PresetSheetView` as a sheet.

```swift
// Inside TextEditSheet, add state and button:
@State private var showPresets: Bool = false

// In the sheet's toolbar or bottom bar:
Button {
    showPresets = true
} label: {
    Label("Presets", systemImage: "paintbrush.pointed")
        .font(.system(size: DS.Typography.body))
        .foregroundStyle(DS.Colors.accent)
}
.sheet(isPresented: $showPresets) {
    PresetSheetView()
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
}
```

- [ ] **Step 2:** Build and visually verify the presets sheet opens from the text editor and applying a preset updates the layer in real time.

```bash
flowdeck build && flowdeck run
```

- [ ] **Step 3:** Commit tasks 7–11.

```bash
cd /Users/s3nik/Desktop/instagram-story-builder
git add ios-native/Glyph/Sources/Models/StylePreset.swift \
        ios-native/Glyph/Sources/Store/PresetStore.swift \
        ios-native/Glyph/Sources/Views/PresetRowView.swift \
        ios-native/Glyph/Sources/Views/PresetSheetView.swift \
        ios-native/Glyph/Sources/Views/TextEditSheet.swift
git commit -m "feat: style presets — model, store, and full sheet UI"
```

---

### Task 12: Unit Tests for AlignmentEngine
**Files:** Create: `ios-native/GlyphTests/AlignmentEngineTests.swift`

- [ ] **Step 1:** Write fast, pure unit tests for the snap engine — no UI, no simulator needed.

```swift
// GlyphTests/AlignmentEngineTests.swift
import Testing
@testable import Glyph

struct AlignmentEngineTests {

    let canvasSize = CGSize(width: 390, height: 844)
    let layerSize = CGSize(width: 100, height: 40)

    @Test("No snap when outside threshold")
    func noSnapOutsideThreshold() {
        let position = CGSize(width: 50, height: 50) // far from center
        let (snapped, guides) = AlignmentEngine.snapPosition(
            position,
            layerSize: layerSize,
            otherLayers: [],
            canvasSize: canvasSize,
            threshold: AlignmentEngine.defaultThreshold
        )
        #expect(snapped == position)
        #expect(guides.isEmpty)
    }

    @Test("Snaps layer center to canvas horizontal center")
    func snapsToCenterX() {
        // Place layer center 5pt away from canvas center X (within 8pt threshold)
        let position = CGSize(width: 5, height: 80)
        let (snapped, guides) = AlignmentEngine.snapPosition(
            position,
            layerSize: layerSize,
            otherLayers: [],
            canvasSize: canvasSize,
            threshold: AlignmentEngine.defaultThreshold
        )
        #expect(snapped.width == 0)
        #expect(guides.contains { $0.axis == .vertical && $0.kind == .centerCanvas })
    }

    @Test("Snaps layer center to canvas vertical center")
    func snapsToCenterY() {
        let position = CGSize(width: 80, height: 4)
        let (snapped, guides) = AlignmentEngine.snapPosition(
            position,
            layerSize: layerSize,
            otherLayers: [],
            canvasSize: canvasSize,
            threshold: AlignmentEngine.defaultThreshold
        )
        #expect(snapped.height == 0)
        #expect(guides.contains { $0.axis == .horizontal && $0.kind == .centerCanvas })
    }

    @Test("Snaps to another layer's right edge")
    func snapsToOtherLayerEdge() {
        let other = LayerGeometry(position: CGSize(width: -100, height: 0), size: CGSize(width: 80, height: 40))
        // other.maxX = -100 + 40 = -60
        // Put dragged layer's left edge 4pt away from other.maxX → dragged center = -60 + layerHalfW - 4
        let draggedCenter = other.maxX + (layerSize.width / 2) - 4
        let position = CGSize(width: draggedCenter, height: 50)
        let (snapped, guides) = AlignmentEngine.snapPosition(
            position,
            layerSize: layerSize,
            otherLayers: [other],
            canvasSize: canvasSize,
            threshold: AlignmentEngine.defaultThreshold
        )
        #expect(snapped.width == other.maxX + layerSize.width / 2)
        #expect(guides.contains { $0.kind == .layerEdge })
    }

    @Test("No snap outside threshold for other layer")
    func noSnapOtherLayerOutsideThreshold() {
        let other = LayerGeometry(position: CGSize(width: -100, height: 0), size: CGSize(width: 80, height: 40))
        let position = CGSize(width: 50, height: 50) // nowhere near other layer
        let (snapped, guides) = AlignmentEngine.snapPosition(
            position,
            layerSize: layerSize,
            otherLayers: [other],
            canvasSize: canvasSize,
            threshold: AlignmentEngine.defaultThreshold
        )
        #expect(snapped == position)
        #expect(guides.filter { $0.kind == .layerEdge }.isEmpty)
    }
}
```

- [ ] **Step 2:** Run the tests.

```bash
flowdeck test --target GlyphTests
```

- [ ] **Step 3:** Final commit.

```bash
cd /Users/s3nik/Desktop/instagram-story-builder
git add ios-native/GlyphTests/AlignmentEngineTests.swift
git commit -m "test: unit tests for AlignmentEngine snap logic"
```

---

## Acceptance Criteria

- [ ] Grid overlay (8×14 and rule-of-thirds) toggles on/off from toolbar with no performance regression
- [ ] Snap guides appear in real time when a layer aligns with canvas center or another layer edge
- [ ] `UIImpactFeedbackGenerator(.light)` fires exactly once per new snap engagement
- [ ] Two-finger drag constrains movement to horizontal or vertical axis
- [ ] All 4 `AlignmentEngine` unit tests pass with `flowdeck test`
- [ ] At least 5 built-in presets visible in the preset sheet
- [ ] User can save, rename, delete, and reorder custom presets
- [ ] Applying a preset updates the selected layer in real time
- [ ] Preset data survives app restart (JSON round-trip verified)
- [ ] All DS tokens used for every spacing, color, radius, and typography value — no raw literals
