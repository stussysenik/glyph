import SwiftUI
import Observation

@Observable
final class CanvasViewModel {

    // MARK: - Canvas state

    /// Canvas dimensions — set from GeometryReader in CanvasView.
    var canvasSize: CGSize = .zero

    /// Snap threshold in points — synced from SettingsViewModel.
    var snapThreshold: Double = 8.0

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

    // MARK: - Guide / Snap state

    /// Whether the guide overlay (grid + snap lines) is visible.
    var showGuides: Bool = false

    /// Whether the rule-of-thirds grid is drawn (vs. the 8×14 grid).
    var useRuleOfThirds: Bool = false

    /// Active snap guides computed during a drag — cleared on drag end.
    var activeGuides: [Guide] = []

    /// When true, layer movement is constrained to horizontal or vertical axis.
    var axisConstrained: Bool = false

    /// The dominant axis when axisConstrained is true.
    var constrainedAxis: GuideAxis? = nil

    func updateActiveGuides(_ guides: [Guide]) {
        activeGuides = guides
    }

    func clearActiveGuides() {
        activeGuides = []
        constrainedAxis = nil
    }

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

    func addTextLayer(fontFamily: String = "Playfair Display") {
        var layer = TextLayer()
        layer.zIndex = nextZIndex()
        layer.name = "Text \(layers.count + 1)"
        layer.fontFamily = fontFamily
        layers.append(layer)
        selectedLayerID = layer.id
        isEditing = true
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
        clearActiveGuides()
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
        guard var layer = layers.first(where: { $0.id == id }) else { return }

        if canvasSize == .zero {
            layer.position = position
            replaceLayer(layer)
            return
        }

        let layerSize = boundingSize(for: layer)
        let others = otherLayerGeometries(excluding: id)
        let (snapped, guides) = AlignmentEngine.snapPosition(
            position,
            layerSize: layerSize,
            otherLayers: others,
            canvasSize: canvasSize,
            threshold: CGFloat(snapThreshold)
        )

        layer.position = snapped
        replaceLayer(layer)
        updateActiveGuides(guides)
    }

    func updateScale(id: UUID, scale: CGFloat) {
        if var layer = layers.first(where: { $0.id == id }) {
            layer.scale = max(0.3, min(5.0, scale))
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

    func moveLayer(from source: IndexSet, to destination: Int) {
        layers.move(fromOffsets: source, toOffset: destination)
        renumberZIndices()
    }

    // MARK: - Keyboard nudge

    /// Moves the selected layer by (dx, dy) points — called from arrow-key shortcuts in CanvasView.
    /// Respects the layer's locked state; locked layers are silently skipped.
    func nudgeSelected(dx: CGFloat, dy: CGFloat) {
        guard let id = selectedLayerID else { return }
        if var layer = layers.first(where: { $0.id == id }), !layer.isLocked {
            layer.position = CGSize(
                width: layer.position.width + dx,
                height: layer.position.height + dy
            )
            replaceLayer(layer)
        }
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

    /// Approximate bounding size for snap calculations.
    private func boundingSize(for layer: any Layer) -> CGSize {
        if let text = layer as? TextLayer {
            let estimatedWidth = text.fontSize * CGFloat(max(text.text.count, 3)) * 0.6
            return CGSize(width: min(estimatedWidth, 300), height: text.fontSize * 1.4)
        } else if let img = layer as? ImageLayer {
            let baseWidth: CGFloat = 200
            return CGSize(width: baseWidth, height: baseWidth / img.aspectRatio)
        }
        return CGSize(width: 100, height: 40)
    }

    /// Build LayerGeometry array for all visible layers except the given ID.
    private func otherLayerGeometries(excluding id: UUID) -> [LayerGeometry] {
        layers.filter { $0.id != id && $0.isVisible }.map { layer in
            LayerGeometry(position: layer.position, size: boundingSize(for: layer))
        }
    }

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
