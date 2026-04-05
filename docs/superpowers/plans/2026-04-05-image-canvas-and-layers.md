# Image Canvas & Layer System — Implementation Plan

> **For agentic workers:** Use superpowers:subagent-driven-development or superpowers:executing-plans.

**Goal:** Extend Glyph's white canvas into a full image-capable canvas with a structured layer system supporting z-ordering, lock, visibility, and multi-select across text and image overlays.

**Architecture:** A unified `Layer` protocol replaces bare `TextOverlay`, with concrete `TextLayer` and `ImageLayer` types stored in `CanvasViewModel`. The background image is a separate first-class property on `CanvasViewModel` — not a layer — and is composited first in export. A new `LayerPanelView` (bottom sheet) drives reorder/lock/visibility, while `CanvasViewModel` becomes the single source of truth for all layer state.

**Tech Stack:** SwiftUI, PHPickerViewController, UIGraphicsImageRenderer, @Observable

---

## File Map

| Action | File | Purpose |
|--------|------|---------|
| **Create** | `Sources/Models/CanvasLayer.swift` | `Layer` protocol + `TextLayer` + `ImageLayer` concrete types |
| **Create** | `Sources/Models/CanvasBackground.swift` | Background image model with pan/zoom state |
| **Create** | `Sources/Views/ImagePickerView.swift` | PHPickerViewController UIViewControllerRepresentable wrapper |
| **Create** | `Sources/Views/BackgroundImageView.swift` | Pinch-to-zoom, pan background with clipped 9:16 frame |
| **Create** | `Sources/Views/ImageOverlayView.swift` | Draggable/resizable image overlay (mirrors TextOverlayView) |
| **Create** | `Sources/Views/LayerPanelView.swift` | Bottom sheet: layer list, drag-to-reorder, lock, visibility, multi-select |
| **Modify** | `Sources/ViewModels/CanvasViewModel.swift` | Replace `overlays: [TextOverlay]` with `layers: [any Layer]`, add background, lock/visibility/multi-select |
| **Modify** | `Sources/Views/CanvasView.swift` | Use new layer types, add image import entry points, wire LayerPanelView sheet |
| **Modify** | `Sources/Services/ExportEngine.swift` | Composite: background → image layers → text layers in z-order |
| **Modify** | `Sources/Views/TextOverlayView.swift` | Read `isLocked`/`isVisible` from layer; disable gestures when locked |

---

### Task 1: Layer Protocol & Models

**Files:**
- Create: `Sources/Models/CanvasLayer.swift`
- Create: `Sources/Models/CanvasBackground.swift`

- [ ] **Step 1: Define the `Layer` protocol and concrete layer types**

```swift
// Sources/Models/CanvasLayer.swift
import SwiftUI

// MARK: - Layer Protocol

/// Base protocol for every canvas overlay — text or image.
/// Conformers are value types stored in CanvasViewModel.layers.
protocol Layer: Identifiable, Sendable {
    var id: UUID { get }
    var name: String { get set }
    var position: CGSize { get set }
    var scale: CGFloat { get set }
    var rotation: Angle { get set }
    var zIndex: Int { get set }
    var isLocked: Bool { get set }
    var isVisible: Bool { get set }
}

// MARK: - TextLayer

/// A text annotation overlay — migrated from TextOverlay.
struct TextLayer: Layer {
    var id: UUID = UUID()
    var name: String = "Text"
    var position: CGSize = .zero
    var scale: CGFloat = 1.0
    var rotation: Angle = .zero
    var zIndex: Int = 0
    var isLocked: Bool = false
    var isVisible: Bool = true

    // Text-specific properties
    var text: String = "Tap to edit"
    var fontFamily: String = "Inter"
    var fontSize: CGFloat = 32
    var textColor: Color = .white
    var alignment: TextAlignment = .center
    var letterSpacing: CGFloat = 0
}

// MARK: - ImageLayer

/// A raster image overlay — draggable, resizable, rotatable.
struct ImageLayer: Layer {
    var id: UUID = UUID()
    var name: String = "Image"
    var position: CGSize = .zero
    var scale: CGFloat = 1.0
    var rotation: Angle = .zero
    var zIndex: Int = 0
    var isLocked: Bool = false
    var isVisible: Bool = true

    // Image-specific properties
    var image: UIImage
    /// Aspect ratio of the original image (width / height)
    var aspectRatio: CGFloat

    init(image: UIImage, name: String = "Image") {
        self.image = image
        self.name = name
        let size = image.size
        self.aspectRatio = size.height > 0 ? size.width / size.height : 1.0
    }
}
```

- [ ] **Step 2: Define CanvasBackground model**

```swift
// Sources/Models/CanvasBackground.swift
import SwiftUI

/// The full-bleed 9:16 background behind all layers.
/// Stores the source image plus interactive pan/zoom state.
struct CanvasBackground: Sendable {
    var image: UIImage
    /// Current scale applied by the user's pinch gesture (clamped 1x–5x)
    var scale: CGFloat = 1.0
    /// Cumulative pan offset from the image's natural center
    var offset: CGSize = .zero

    init(image: UIImage) {
        self.image = image
    }
}
```

- [ ] **Step 3: Build verification**

```bash
xcodebuild build -scheme Glyph -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -quiet
```

---

### Task 2: CanvasViewModel Migration

**Files:**
- Modify: `Sources/ViewModels/CanvasViewModel.swift`

- [ ] **Step 1: Replace TextOverlay array with typed Layer array and add background + multi-select state**

```swift
// Sources/ViewModels/CanvasViewModel.swift
import SwiftUI
import Observation

@Observable
final class CanvasViewModel {

    // MARK: - Canvas state

    /// Optional full-bleed background image
    var background: CanvasBackground?

    /// All canvas overlays in display order (ascending zIndex)
    var layers: [any Layer] = []

    /// ID of the single-selected layer (nil = nothing selected)
    var selectedLayerID: UUID?

    /// IDs active during multi-select mode
    var multiSelectedIDs: Set<UUID> = []

    /// Whether we are in multi-select mode
    var isMultiSelectActive: Bool = false

    /// Whether the selected text layer is being inline-edited
    var isEditing: Bool = false

    // MARK: - Background

    func setBackground(_ image: UIImage) {
        background = CanvasBackground(image: image)
    }

    func clearBackground() {
        background = nil
    }

    func updateBackgroundScale(_ scale: CGFloat) {
        background?.scale = max(1.0, min(scale, 5.0))
    }

    func updateBackgroundOffset(_ offset: CGSize) {
        background?.offset = offset
    }

    // MARK: - Layer CRUD

    func addTextLayer() {
        var layer = TextLayer()
        layer.zIndex = nextZIndex()
        layer.name = "Text \(layers.count + 1)"
        layers.append(layer)
        selectedLayerID = layer.id
    }

    func addImageLayer(_ image: UIImage) {
        var layer = ImageLayer(image: image)
        layer.zIndex = nextZIndex()
        layer.name = "Image \(layers.count + 1)"
        layers.append(layer)
        selectedLayerID = layer.id
    }

    func removeLayer(id: UUID) {
        layers.removeAll { $0.id == id }
        if selectedLayerID == id { selectedLayerID = nil }
        multiSelectedIDs.remove(id)
        renumberZIndices()
    }

    func removeSelectedLayers() {
        if isMultiSelectActive {
            layers.removeAll { multiSelectedIDs.contains($0.id) }
            multiSelectedIDs.removeAll()
            isMultiSelectActive = false
        } else if let id = selectedLayerID {
            removeLayer(id: id)
        }
    }

    // MARK: - Selection

    func selectLayer(id: UUID) {
        if isMultiSelectActive {
            if multiSelectedIDs.contains(id) {
                multiSelectedIDs.remove(id)
            } else {
                multiSelectedIDs.insert(id)
            }
        } else {
            selectedLayerID = id
            isEditing = false
        }
    }

    func deselectAll() {
        selectedLayerID = nil
        isEditing = false
        if isMultiSelectActive {
            multiSelectedIDs.removeAll()
            isMultiSelectActive = false
        }
    }

    func enterMultiSelect(startingWith id: UUID) {
        isMultiSelectActive = true
        multiSelectedIDs.insert(id)
        selectedLayerID = nil
    }

    // MARK: - Layer properties (generic mutator)

    func updateLayer<T: Layer>(id: UUID, transform: (inout T) -> Void) {
        guard let idx = layers.firstIndex(where: { $0.id == id }),
              var typed = layers[idx] as? T else { return }
        transform(&typed)
        layers[idx] = typed
    }

    // MARK: - TextLayer convenience mutators

    func updateText(id: UUID, text: String) {
        updateLayer(id: id) { (l: inout TextLayer) in l.text = text }
    }

    func updateFont(id: UUID, fontFamily: String) {
        updateLayer(id: id) { (l: inout TextLayer) in l.fontFamily = fontFamily }
    }

    func updateFontSize(id: UUID, fontSize: CGFloat) {
        updateLayer(id: id) { (l: inout TextLayer) in l.fontSize = fontSize }
    }

    func updateColor(id: UUID, color: Color) {
        updateLayer(id: id) { (l: inout TextLayer) in l.textColor = color }
    }

    func updateAlignment(id: UUID, alignment: TextAlignment) {
        updateLayer(id: id) { (l: inout TextLayer) in l.alignment = alignment }
    }

    func updateLetterSpacing(id: UUID, spacing: CGFloat) {
        updateLayer(id: id) { (l: inout TextLayer) in l.letterSpacing = spacing }
    }

    // MARK: - Layer transform mutators (both types)

    func updatePosition(id: UUID, position: CGSize) {
        if var layer = layers.first(where: { $0.id == id }) {
            layer.position = position
            replaceLayer(layer)
        }
    }

    func updateScale(id: UUID, scale: CGFloat) {
        if var layer = layers.first(where: { $0.id == id }) {
            layer.scale = scale
            replaceLayer(layer)
        }
    }

    func updateRotation(id: UUID, rotation: Angle) {
        if var layer = layers.first(where: { $0.id == id }) {
            layer.rotation = rotation
            replaceLayer(layer)
        }
    }

    // MARK: - Lock / Visibility / Z-order

    func toggleLock(id: UUID) {
        if var layer = layers.first(where: { $0.id == id }) {
            layer.isLocked.toggle()
            replaceLayer(layer)
        }
    }

    func toggleVisibility(id: UUID) {
        if var layer = layers.first(where: { $0.id == id }) {
            layer.isVisible.toggle()
            replaceLayer(layer)
        }
    }

    /// Move layer at `from` index to `to` index within the layers array,
    /// then renumber zIndices to match the new order.
    func moveLayer(from source: IndexSet, to destination: Int) {
        layers.move(fromOffsets: source, toOffset: destination)
        renumberZIndices()
    }

    // MARK: - Batch (multi-select)

    func batchMoveSelectedLayers(by delta: CGSize) {
        for id in multiSelectedIDs {
            if var layer = layers.first(where: { $0.id == id }) {
                layer.position = CGSize(
                    width: layer.position.width + delta.width,
                    height: layer.position.height + delta.height
                )
                replaceLayer(layer)
            }
        }
    }

    // MARK: - Computed helpers

    var sortedLayers: [any Layer] {
        layers.sorted { $0.zIndex < $1.zIndex }
    }

    var selectedTextLayer: TextLayer? {
        guard let id = selectedLayerID else { return nil }
        return layers.first(where: { $0.id == id }) as? TextLayer
    }

    // MARK: - Private helpers

    private func nextZIndex() -> Int {
        (layers.map(\.zIndex).max() ?? -1) + 1
    }

    private func renumberZIndices() {
        for i in layers.indices {
            layers[i].zIndex = i
        }
    }

    private func replaceLayer(_ layer: some Layer) {
        guard let idx = layers.firstIndex(where: { $0.id == layer.id }) else { return }
        layers[idx] = layer
    }
}
```

- [ ] **Step 2: Build verification**

```bash
xcodebuild build -scheme Glyph -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -quiet
```

---

### Task 3: PHPicker Image Import

**Files:**
- Create: `Sources/Views/ImagePickerView.swift`

- [ ] **Step 1: Wrap PHPickerViewController as a UIViewControllerRepresentable**

```swift
// Sources/Views/ImagePickerView.swift
import SwiftUI
import PhotosUI

/// Presents PHPickerViewController and delivers a single UIImage via callback.
/// Usage: .sheet(isPresented: $showPicker) { ImagePickerView { vm.setBackground($0) } }
struct ImagePickerView: UIViewControllerRepresentable {

    /// Called with the selected UIImage on the main actor.
    var onImagePicked: @MainActor (UIImage) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onImagePicked: onImagePicked) }

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.selectionLimit = 1
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    // MARK: - Coordinator

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {

        private let onImagePicked: @MainActor (UIImage) -> Void

        init(onImagePicked: @escaping @MainActor (UIImage) -> Void) {
            self.onImagePicked = onImagePicked
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            guard let provider = results.first?.itemProvider,
                  provider.canLoadObject(ofClass: UIImage.self) else { return }

            provider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
                guard let image = object as? UIImage else { return }
                Task { @MainActor [weak self] in
                    self?.onImagePicked(image)
                }
            }
        }
    }
}
```

- [ ] **Step 2: Build verification**

```bash
xcodebuild build -scheme Glyph -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -quiet
```

---

### Task 4: Background Image View

**Files:**
- Create: `Sources/Views/BackgroundImageView.swift`

- [ ] **Step 1: Build the pinch-to-zoom, pannable background view**

```swift
// Sources/Views/BackgroundImageView.swift
import SwiftUI

/// Renders the canvas background at 9:16 with interactive pan and pinch-to-zoom.
/// Clips to the canvas frame — overflow is hidden.
struct BackgroundImageView: View {
    private typealias DS = GlyphDesignSystem

    var background: CanvasBackground
    var onScaleChange: (CGFloat) -> Void
    var onOffsetChange: (CGSize) -> Void

    // Gesture state
    @GestureState private var gestureScale: CGFloat = 1.0
    @GestureState private var gestureDrag: CGSize = .zero

    var body: some View {
        Image(uiImage: background.image)
            .resizable()
            .scaledToFill()
            .scaleEffect(background.scale * gestureScale)
            .offset(
                x: background.offset.width + gestureDrag.width,
                y: background.offset.height + gestureDrag.height
            )
            .clipped()
            .gesture(pinchGesture)
            .gesture(panGesture)
    }

    // MARK: - Gestures

    private var pinchGesture: some Gesture {
        MagnificationGesture()
            .updating($gestureScale) { value, state, _ in state = value }
            .onEnded { value in
                onScaleChange(background.scale * value)
            }
    }

    private var panGesture: some Gesture {
        DragGesture()
            .updating($gestureDrag) { value, state, _ in state = value.translation }
            .onEnded { value in
                onOffsetChange(CGSize(
                    width: background.offset.width + value.translation.width,
                    height: background.offset.height + value.translation.height
                ))
            }
    }
}

/// Placeholder shown when no background has been set.
struct EmptyBackgroundView: View {
    private typealias DS = GlyphDesignSystem
    var body: some View {
        Rectangle()
            .fill(DS.Colors.canvas)
    }
}
```

- [ ] **Step 2: Build verification**

```bash
xcodebuild build -scheme Glyph -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -quiet
```

---

### Task 5: Image Overlay View

**Files:**
- Create: `Sources/Views/ImageOverlayView.swift`

- [ ] **Step 1: Build draggable/resizable/rotatable image overlay (mirrors TextOverlayView pattern)**

```swift
// Sources/Views/ImageOverlayView.swift
import SwiftUI

/// A single image layer rendered on the canvas with drag, pinch, and rotate gestures.
/// Gestures are disabled when the layer is locked.
struct ImageOverlayView: View {
    private typealias DS = GlyphDesignSystem

    var layer: ImageLayer
    var isSelected: Bool
    var onSelect: () -> Void
    var onLongPress: () -> Void
    var onPositionChange: (CGSize) -> Void
    var onScaleChange: (CGFloat) -> Void
    var onRotationChange: (Angle) -> Void

    // Gesture state
    @GestureState private var dragOffset: CGSize = .zero
    @GestureState private var gestureScale: CGFloat = 1.0
    @GestureState private var gestureRotation: Angle = .zero

    private let baseWidth: CGFloat = 200

    var body: some View {
        Image(uiImage: layer.image)
            .resizable()
            .aspectRatio(layer.aspectRatio, contentMode: .fit)
            .frame(width: baseWidth)
            .scaleEffect(layer.scale * gestureScale)
            .rotationEffect(layer.rotation + gestureRotation)
            .offset(
                x: layer.position.width + dragOffset.width,
                y: layer.position.height + dragOffset.height
            )
            .overlay(selectionBorder)
            .opacity(layer.isVisible ? 1 : 0)
            .allowsHitTesting(layer.isVisible)
            .gesture(layer.isLocked ? nil : combinedGesture)
            .onTapGesture { onSelect() }
            .onLongPressGesture(minimumDuration: 0.4) { onLongPress() }
    }

    // MARK: - Selection border

    @ViewBuilder
    private var selectionBorder: some View {
        if isSelected {
            RoundedRectangle(cornerRadius: DS.Radius.sm)
                .stroke(
                    layer.isLocked ? DS.Colors.textTertiary : DS.Colors.accent,
                    style: StrokeStyle(lineWidth: 2, dash: layer.isLocked ? [6, 3] : [])
                )
                .padding(-4)
        }
    }

    // MARK: - Combined gesture

    private var combinedGesture: some Gesture {
        SimultaneousGesture(
            DragGesture()
                .updating($dragOffset) { value, state, _ in state = value.translation }
                .onEnded { value in
                    onPositionChange(CGSize(
                        width: layer.position.width + value.translation.width,
                        height: layer.position.height + value.translation.height
                    ))
                },
            SimultaneousGesture(
                MagnificationGesture()
                    .updating($gestureScale) { value, state, _ in state = value }
                    .onEnded { value in onScaleChange(layer.scale * value) },
                RotationGesture()
                    .updating($gestureRotation) { value, state, _ in state = value }
                    .onEnded { value in onRotationChange(layer.rotation + value) }
            )
        )
    }
}
```

- [ ] **Step 2: Build verification**

```bash
xcodebuild build -scheme Glyph -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -quiet
```

---

### Task 6: Update TextOverlayView for Layer Protocol

**Files:**
- Modify: `Sources/Views/TextOverlayView.swift`

- [ ] **Step 1: Replace TextOverlay parameter with TextLayer; disable gestures when locked; dim when hidden**

```swift
// Sources/Views/TextOverlayView.swift  (full replacement)
import SwiftUI

/// Renders a single TextLayer on the canvas with drag, pinch, and rotate gestures.
/// Gestures are disabled and the selection border dashes when the layer is locked.
struct TextOverlayView: View {
    private typealias DS = GlyphDesignSystem

    var layer: TextLayer
    var isSelected: Bool
    var onSelect: () -> Void
    var onEdit: () -> Void
    var onPositionChange: (CGSize) -> Void
    var onScaleChange: (CGFloat) -> Void
    var onRotationChange: (Angle) -> Void

    @GestureState private var dragOffset: CGSize = .zero
    @GestureState private var gestureScale: CGFloat = 1.0
    @GestureState private var gestureRotation: Angle = .zero

    var body: some View {
        Text(layer.text.isEmpty ? " " : layer.text)
            .font(.custom(layer.fontFamily, size: layer.fontSize))
            .foregroundStyle(layer.textColor)
            .multilineTextAlignment(layer.alignment)
            .tracking(layer.letterSpacing)
            .padding(.horizontal, DS.Spacing.sm)
            .scaleEffect(layer.scale * gestureScale)
            .rotationEffect(layer.rotation + gestureRotation)
            .offset(
                x: layer.position.width + dragOffset.width,
                y: layer.position.height + dragOffset.height
            )
            .overlay(selectionBorder)
            .opacity(layer.isVisible ? 1 : 0)
            .allowsHitTesting(layer.isVisible)
            .gesture(layer.isLocked ? nil : combinedGesture)
            .onTapGesture { onSelect() }
            .onLongPressGesture(minimumDuration: 0.4) { onEdit() }
    }

    @ViewBuilder
    private var selectionBorder: some View {
        if isSelected {
            RoundedRectangle(cornerRadius: DS.Radius.sm)
                .stroke(
                    layer.isLocked ? DS.Colors.textTertiary : DS.Colors.accent,
                    style: StrokeStyle(lineWidth: 2, dash: layer.isLocked ? [6, 3] : [])
                )
                .padding(-6)
        }
    }

    private var combinedGesture: some Gesture {
        SimultaneousGesture(
            DragGesture()
                .updating($dragOffset) { value, state, _ in state = value.translation }
                .onEnded { value in
                    onPositionChange(CGSize(
                        width: layer.position.width + value.translation.width,
                        height: layer.position.height + value.translation.height
                    ))
                },
            SimultaneousGesture(
                MagnificationGesture()
                    .updating($gestureScale) { value, state, _ in state = value }
                    .onEnded { value in onScaleChange(layer.scale * value) },
                RotationGesture()
                    .updating($gestureRotation) { value, state, _ in state = value }
                    .onEnded { value in onRotationChange(layer.rotation + value) }
            )
        )
    }
}
```

- [ ] **Step 2: Build verification**

```bash
xcodebuild build -scheme Glyph -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -quiet
```

---

### Task 7: Layer Panel View

**Files:**
- Create: `Sources/Views/LayerPanelView.swift`

- [ ] **Step 1: Build the layer list bottom sheet with drag-to-reorder, lock, visibility, and tap-to-select**

```swift
// Sources/Views/LayerPanelView.swift
import SwiftUI

/// Bottom sheet showing all layers in z-order (top = front).
/// Supports: tap to select, drag to reorder, lock toggle, visibility toggle.
struct LayerPanelView: View {
    private typealias DS = GlyphDesignSystem

    @Environment(CanvasViewModel.self) private var vm

    var body: some View {
        NavigationStack {
            Group {
                if vm.layers.isEmpty {
                    emptyState
                } else {
                    layerList
                }
            }
            .navigationTitle("Layers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .background(DS.Colors.surface.ignoresSafeArea())
        }
    }

    // MARK: - Layer list

    private var layerList: some View {
        List {
            ForEach(vm.layers.reversed(), id: \.id) { layer in
                LayerRowView(
                    layer: layer,
                    isSelected: vm.selectedLayerID == layer.id
                        || vm.multiSelectedIDs.contains(layer.id)
                ) {
                    vm.selectLayer(id: layer.id)
                }
                .listRowBackground(
                    (vm.selectedLayerID == layer.id || vm.multiSelectedIDs.contains(layer.id))
                        ? DS.Colors.accent.opacity(0.12)
                        : DS.Colors.surface
                )
                .listRowInsets(EdgeInsets(
                    top: DS.Spacing.xs,
                    leading: DS.Spacing.md,
                    bottom: DS.Spacing.xs,
                    trailing: DS.Spacing.md
                ))
            }
            .onMove { source, destination in
                // List shows reversed order so we must mirror the move
                let totalCount = vm.layers.count
                let mirroredSource = IndexSet(source.map { totalCount - 1 - $0 })
                let mirroredDest = totalCount - destination
                vm.moveLayer(from: mirroredSource, to: mirroredDest)
            }
        }
        .listStyle(.plain)
        .environment(\.editMode, .constant(.active))
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: DS.Spacing.md) {
            Image(systemName: "square.stack.3d.up")
                .font(.system(size: 40))
                .foregroundStyle(DS.Colors.textTertiary)
            Text("No layers yet")
                .font(.system(size: DS.Typography.body))
                .foregroundStyle(DS.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            if vm.isMultiSelectActive {
                Button("Delete Selected", role: .destructive) {
                    vm.removeSelectedLayers()
                }
                .foregroundStyle(DS.Colors.error)
            }
        }
    }
}

// MARK: - LayerRowView

private struct LayerRowView: View {
    private typealias DS = GlyphDesignSystem

    var layer: any Layer
    var isSelected: Bool
    var onTap: () -> Void

    @Environment(CanvasViewModel.self) private var vm

    var body: some View {
        HStack(spacing: DS.Spacing.md) {
            // Thumbnail
            layerThumbnail

            // Name
            Text(layer.name)
                .font(.system(size: DS.Typography.body, weight: .medium))
                .foregroundStyle(DS.Colors.textPrimary)
                .lineLimit(1)

            Spacer()

            // Lock toggle
            Button {
                vm.toggleLock(id: layer.id)
            } label: {
                Image(systemName: layer.isLocked ? "lock.fill" : "lock.open")
                    .font(.system(size: 16))
                    .foregroundStyle(layer.isLocked ? DS.Colors.accent : DS.Colors.textTertiary)
            }
            .buttonStyle(.plain)

            // Visibility toggle
            Button {
                vm.toggleVisibility(id: layer.id)
            } label: {
                Image(systemName: layer.isVisible ? "eye" : "eye.slash")
                    .font(.system(size: 16))
                    .foregroundStyle(layer.isVisible ? DS.Colors.textSecondary : DS.Colors.textTertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, DS.Spacing.xs)
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
    }

    @ViewBuilder
    private var layerThumbnail: some View {
        RoundedRectangle(cornerRadius: DS.Radius.sm)
            .fill(DS.Colors.surfaceAlt)
            .frame(width: 36, height: 36)
            .overlay {
                if let imageLayer = layer as? ImageLayer {
                    Image(uiImage: imageLayer.image)
                        .resizable()
                        .scaledToFill()
                        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.sm))
                } else if let textLayer = layer as? TextLayer {
                    Text(String(textLayer.text.prefix(2)))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(DS.Colors.textPrimary)
                }
            }
    }
}
```

- [ ] **Step 2: Build verification**

```bash
xcodebuild build -scheme Glyph -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -quiet
```

---

### Task 8: Update CanvasView

**Files:**
- Modify: `Sources/Views/CanvasView.swift`

- [ ] **Step 1: Wire background image view, image overlay rendering, image import buttons, and layer panel sheet**

```swift
// Sources/Views/CanvasView.swift  (key structural sections — integrate with existing sheet/toolbar code)
import SwiftUI

struct CanvasView: View {
    private typealias DS = GlyphDesignSystem

    @Environment(CanvasViewModel.self) private var vm
    @Environment(FontLibraryViewModel.self) private var fontLibrary

    // Sheet state
    @State private var showStyleSheet = false
    @State private var showFontSheet = false
    @State private var showExportSheet = false
    @State private var showLayerPanel = false
    @State private var showBackgroundPicker = false
    @State private var showImageOverlayPicker = false

    // Canvas geometry
    private let canvasWidth: CGFloat = UIScreen.main.bounds.width
    private var canvasHeight: CGFloat { canvasWidth * (16.0 / 9.0) }

    var body: some View {
        VStack(spacing: 0) {
            topToolbar
            canvas
            bottomControls
        }
        .background(DS.Colors.surface.ignoresSafeArea())
        // Sheets
        .sheet(isPresented: $showBackgroundPicker) {
            ImagePickerView { image in
                vm.setBackground(image)
                showBackgroundPicker = false
            }
        }
        .sheet(isPresented: $showImageOverlayPicker) {
            ImagePickerView { image in
                vm.addImageLayer(image)
                showImageOverlayPicker = false
            }
        }
        .sheet(isPresented: $showLayerPanel) {
            LayerPanelView()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showStyleSheet) {
            // Existing StyleSheet — unchanged
        }
        .sheet(isPresented: $showFontSheet) {
            // Existing FontSheet — unchanged
        }
        .sheet(isPresented: $showExportSheet) {
            ExportSheet()
        }
    }

    // MARK: - Top toolbar

    private var topToolbar: some View {
        HStack {
            // Background import
            Button {
                showBackgroundPicker = true
            } label: {
                Label("BG", systemImage: "photo")
                    .font(.system(size: DS.Typography.label, weight: .medium))
                    .foregroundStyle(DS.Colors.textPrimary)
            }

            // Add image overlay
            Button {
                showImageOverlayPicker = true
            } label: {
                Label("IMAGE", systemImage: "plus.rectangle.on.rectangle")
                    .font(.system(size: DS.Typography.label, weight: .medium))
                    .foregroundStyle(DS.Colors.textPrimary)
            }

            Spacer()

            // Add text
            Button {
                vm.addTextLayer()
            } label: {
                Text("ADD TEXT")
                    .font(.system(size: DS.Typography.label, weight: .medium))
                    .foregroundStyle(DS.Colors.textPrimary)
            }

            // Layer panel
            Button {
                showLayerPanel = true
            } label: {
                Image(systemName: "square.3.layers.3d")
                    .font(.system(size: 18))
                    .foregroundStyle(DS.Colors.textPrimary)
            }

            // Export
            Button {
                showExportSheet = true
            } label: {
                Text("EXPORT")
                    .font(.system(size: DS.Typography.label, weight: .medium))
                    .foregroundStyle(DS.Colors.textPrimary)
            }
        }
        .padding(.horizontal, DS.Spacing.lg)
        .padding(.vertical, DS.Spacing.sm)
        .background(DS.Colors.surface)
    }

    // MARK: - Canvas

    private var canvas: some View {
        ZStack {
            // Background
            if let background = vm.background {
                BackgroundImageView(
                    background: background,
                    onScaleChange: { vm.updateBackgroundScale($0) },
                    onOffsetChange: { vm.updateBackgroundOffset($0) }
                )
            } else {
                EmptyBackgroundView()
            }

            // Layers in z-order
            ForEach(vm.sortedLayers, id: \.id) { layer in
                if let imageLayer = layer as? ImageLayer {
                    ImageOverlayView(
                        layer: imageLayer,
                        isSelected: vm.selectedLayerID == layer.id,
                        onSelect: { vm.selectLayer(id: layer.id) },
                        onLongPress: { vm.enterMultiSelect(startingWith: layer.id) },
                        onPositionChange: { vm.updatePosition(id: layer.id, position: $0) },
                        onScaleChange: { vm.updateScale(id: layer.id, scale: $0) },
                        onRotationChange: { vm.updateRotation(id: layer.id, rotation: $0) }
                    )
                } else if let textLayer = layer as? TextLayer {
                    TextOverlayView(
                        layer: textLayer,
                        isSelected: vm.selectedLayerID == layer.id,
                        onSelect: { vm.selectLayer(id: layer.id) },
                        onEdit: { vm.selectedLayerID = layer.id; vm.isEditing = true },
                        onPositionChange: { vm.updatePosition(id: layer.id, position: $0) },
                        onScaleChange: { vm.updateScale(id: layer.id, scale: $0) },
                        onRotationChange: { vm.updateRotation(id: layer.id, rotation: $0) }
                    )
                }
            }

            // Inline text editor overlay
            if vm.isEditing, let textLayer = vm.selectedTextLayer {
                InlineTextEditorView(layer: textLayer)
            }
        }
        .frame(width: canvasWidth, height: canvasHeight)
        .clipped()
        .contentShape(Rectangle())
        .onTapGesture { vm.deselectAll() }
    }

    // MARK: - Bottom controls (existing pattern — add paste-from-clipboard)

    private var bottomControls: some View {
        HStack(spacing: DS.Spacing.xl) {
            // Paste image from clipboard
            Button {
                if let image = UIPasteboard.general.image {
                    vm.addImageLayer(image)
                }
            } label: {
                controlCircle(icon: "doc.on.clipboard")
            }

            Spacer()

            // Style (only when text layer selected)
            if vm.selectedTextLayer != nil {
                Button { showStyleSheet = true } label: {
                    controlCircle(icon: "textformat")
                }
                Button { showFontSheet = true } label: {
                    controlCircle(icon: "a.magnify")
                }
            }

            // Delete selected
            Button {
                vm.removeSelectedLayers()
            } label: {
                controlCircle(icon: "trash", tint: DS.Colors.error)
            }
            .opacity(
                (vm.selectedLayerID != nil || vm.isMultiSelectActive) ? 1 : 0.3
            )
        }
        .padding(.horizontal, DS.Spacing.xl)
        .padding(.vertical, DS.Spacing.md)
        .background(DS.Colors.surface)
    }

    private func controlCircle(icon: String, tint: Color = DS.Colors.textPrimary) -> some View {
        Image(systemName: icon)
            .font(.system(size: 18, weight: .medium))
            .foregroundStyle(tint)
            .frame(width: 44, height: 44)
            .background(DS.Colors.surfaceAlt)
            .clipShape(Circle())
    }
}

// MARK: - Inline text editor (extracted sub-view)

private struct InlineTextEditorView: View {
    private typealias DS = GlyphDesignSystem

    var layer: TextLayer
    @Environment(CanvasViewModel.self) private var vm
    @FocusState private var isFocused: Bool

    var body: some View {
        TextField("", text: Binding(
            get: { layer.text },
            set: { vm.updateText(id: layer.id, text: $0) }
        ), axis: .vertical)
        .font(.custom(layer.fontFamily, size: layer.fontSize))
        .foregroundStyle(layer.textColor)
        .multilineTextAlignment(layer.alignment)
        .tracking(layer.letterSpacing)
        .padding(DS.Spacing.sm)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md))
        .offset(x: layer.position.width, y: layer.position.height)
        .focused($isFocused)
        .onAppear { isFocused = true }
        .onSubmit { vm.isEditing = false }
    }
}
```

- [ ] **Step 2: Build verification**

```bash
xcodebuild build -scheme Glyph -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -quiet
```

---

### Task 9: Update ExportEngine

**Files:**
- Modify: `Sources/Services/ExportEngine.swift`

- [ ] **Step 1: Composite background → image layers → text layers in z-order using UIGraphicsImageRenderer**

```swift
// Sources/Services/ExportEngine.swift  (key render method — replace existing renderCanvas)
import UIKit

extension ExportEngine {

    /// Renders the full canvas to a 1080×1920 UIImage.
    /// Composite order: background fill → background image → image layers → text layers
    static func renderCanvas(
        background: CanvasBackground?,
        layers: [any Layer],
        canvasSize: CGSize = CGSize(width: 1080, height: 1920)
    ) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: canvasSize)
        return renderer.image { ctx in
            let cgCtx = ctx.cgContext

            // 1. Background fill
            UIColor(GlyphDesignSystem.Colors.canvas).setFill()
            cgCtx.fill(CGRect(origin: .zero, size: canvasSize))

            // 2. Background image (scaled + offset, clipped to canvas)
            if let bg = background {
                cgCtx.saveGState()
                cgCtx.clip(to: CGRect(origin: .zero, size: canvasSize))
                let imgSize = bg.image.size
                let scale = max(canvasSize.width / imgSize.width, canvasSize.height / imgSize.height)
                    * bg.scale
                let drawWidth = imgSize.width * scale
                let drawHeight = imgSize.height * scale
                let drawRect = CGRect(
                    x: (canvasSize.width - drawWidth) / 2 + bg.offset.width,
                    y: (canvasSize.height - drawHeight) / 2 + bg.offset.height,
                    width: drawWidth,
                    height: drawHeight
                )
                bg.image.draw(in: drawRect)
                cgCtx.restoreGState()
            }

            // 3. Image layers in z-order
            let sortedLayers = layers.sorted { $0.zIndex < $1.zIndex }
            for layer in sortedLayers where layer.isVisible {
                guard let imageLayer = layer as? ImageLayer else { continue }
                drawImageLayer(imageLayer, in: cgCtx, canvasSize: canvasSize)
            }

            // 4. Text layers in z-order
            for layer in sortedLayers where layer.isVisible {
                guard let textLayer = layer as? TextLayer else { continue }
                drawTextLayer(textLayer, in: cgCtx, canvasSize: canvasSize)
            }
        }
    }

    // MARK: - Private drawing helpers

    private static func drawImageLayer(
        _ layer: ImageLayer,
        in ctx: CGContext,
        canvasSize: CGSize
    ) {
        let baseWidth: CGFloat = 200 * (canvasSize.width / UIScreen.main.bounds.width)
        let baseHeight = baseWidth / layer.aspectRatio
        let center = CGPoint(
            x: canvasSize.width / 2 + layer.position.width,
            y: canvasSize.height / 2 + layer.position.height
        )

        ctx.saveGState()
        ctx.translateBy(x: center.x, y: center.y)
        ctx.rotate(by: CGFloat(layer.rotation.radians))
        ctx.scaleBy(x: layer.scale, y: layer.scale)

        let drawRect = CGRect(
            x: -baseWidth / 2,
            y: -baseHeight / 2,
            width: baseWidth,
            height: baseHeight
        )
        layer.image.draw(in: drawRect)
        ctx.restoreGState()
    }

    private static func drawTextLayer(
        _ layer: TextLayer,
        in ctx: CGContext,
        canvasSize: CGSize
    ) {
        let center = CGPoint(
            x: canvasSize.width / 2 + layer.position.width,
            y: canvasSize.height / 2 + layer.position.height
        )

        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont(name: layer.fontFamily, size: layer.fontSize)
                ?? UIFont.systemFont(ofSize: layer.fontSize),
            .foregroundColor: UIColor(layer.textColor),
            .kern: layer.letterSpacing
        ]
        let attrString = NSAttributedString(string: layer.text, attributes: attrs)
        let textSize = attrString.boundingRect(
            with: CGSize(width: canvasSize.width * 0.8, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin],
            context: nil
        ).size

        ctx.saveGState()
        ctx.translateBy(x: center.x, y: center.y)
        ctx.rotate(by: CGFloat(layer.rotation.radians))
        ctx.scaleBy(x: layer.scale, y: layer.scale)

        attrString.draw(in: CGRect(
            x: -textSize.width / 2,
            y: -textSize.height / 2,
            width: textSize.width,
            height: textSize.height
        ))
        ctx.restoreGState()
    }
}
```

- [ ] **Step 2: Build verification**

```bash
xcodebuild build -scheme Glyph -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -quiet
```

---

### Task 10: ExportSheet & GlyphApp Wiring

**Files:**
- Modify: `Sources/Views/ExportSheet.swift`
- Modify: `Sources/GlyphApp.swift`

- [ ] **Step 1: Update ExportSheet to pass background + layers to ExportEngine**

```swift
// In ExportSheet.swift — update the export action to use the new renderCanvas signature
// Replace the existing UIImage generation call with:

@Environment(CanvasViewModel.self) private var vm

private func exportedImage() -> UIImage {
    ExportEngine.renderCanvas(
        background: vm.background,
        layers: vm.layers
    )
}
```

- [ ] **Step 2: Ensure GlyphApp still injects CanvasViewModel correctly (no changes needed if @Observable)**

```swift
// Sources/GlyphApp.swift — confirm environment injection pattern is unchanged.
// CanvasViewModel is @Observable; its new properties (background, layers)
// are automatically observed. No additional injection required.
//
// Verify the entry point still reads:
//   @State private var canvasViewModel = CanvasViewModel()
//   ...
//   .environment(canvasViewModel)
```

- [ ] **Step 3: Final full build and simulator launch**

```bash
xcodebuild build -scheme Glyph -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -quiet
# Then launch in simulator via flowdeck for visual verification
flowdeck run --scheme Glyph --simulator "iPhone 16 Pro"
```

---

## Acceptance Criteria

- [ ] PHPicker opens and selected image appears as the canvas background at 9:16
- [ ] Background supports pinch-to-zoom (1x–5x) and pan without leaving canvas bounds
- [ ] Image overlays can be imported, dragged, scaled, and rotated like text overlays
- [ ] Layer panel shows all layers with correct names, lock, and visibility state
- [ ] Drag-to-reorder in layer panel changes rendering z-order on the canvas immediately
- [ ] Locking a layer disables its drag/pinch/rotate gestures; selection border dashes
- [ ] Hidden layers are invisible on canvas and excluded from hit-testing
- [ ] Long-pressing a layer enters multi-select; bottom bar shows Delete Selected
- [ ] Export composites background + image layers + text layers in correct z-order at 1080×1920
- [ ] All DS tokens used for every colour, spacing, radius, and typography value
