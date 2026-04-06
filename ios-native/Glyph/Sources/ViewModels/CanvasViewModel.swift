import SwiftUI
import UIKit
import Observation

// MARK: - Custom Guide

struct CustomGuide: Identifiable {
    let id: UUID
    let axis: GuideAxis
    var position: CGFloat
    init(axis: GuideAxis, position: CGFloat) {
        self.id = UUID(); self.axis = axis; self.position = position
    }
}

@Observable
final class CanvasViewModel {

    private func announce(_ message: String) {
        UIAccessibility.post(notification: .announcement, argument: message)
    }

    // MARK: - State

    var canvasSize: CGSize = .zero
    var snapThreshold: Double = 8.0
    var background: CanvasBackground?
    var layers: [any Layer] = []
    var selectedLayerID: UUID?
    var multiSelectedIDs: Set<UUID> = []
    var isMultiSelectActive: Bool = false
    var isEditing: Bool = false

    // Undo
    private var undoStack: [UndoSnapshot] = []
    private var redoStack: [UndoSnapshot] = []
    private let maxUndo = 50
    var canUndo: Bool { !undoStack.isEmpty }
    var canRedo: Bool { !redoStack.isEmpty }
    private var lastUndoKey: String?

    // Custom guides
    var customGuides: [CustomGuide] = []

    // Guides
    var showGuides: Bool = false
    var activeGuides: [Guide] = []
    var axisConstrained: Bool = false
    var constrainedAxis: GuideAxis? = nil

    func updateActiveGuides(_ guides: [Guide]) {
        let hadGuides = !activeGuides.isEmpty
        activeGuides = guides
        if !hadGuides, let first = guides.first {
            let msg: String = switch first.kind {
            case .centerCanvas: "Snapped to canvas center"
            case .layerEdge:   "Aligned with nearby layer"
            case .equalSpacing: "Equal spacing"
            }
            announce(msg)
        }
    }

    func clearActiveGuides() { activeGuides = []; constrainedAxis = nil }

    // MARK: - Undo / Redo

    private struct UndoSnapshot {
        let layers: [any Layer]
        let background: CanvasBackground?
        let selectedLayerID: UUID?
    }

    /// Push an undo snapshot. Pass a `coalesceKey` to merge consecutive
    /// pushes from the same continuous gesture (drag / pinch / rotate)
    /// into a single undo entry — prevents the stack from filling with
    /// 50 near-identical frames.
    private func pushUndo(coalesceKey: String? = nil) {
        let snap = UndoSnapshot(layers: layers, background: background, selectedLayerID: selectedLayerID)
        if let key = coalesceKey, key == lastUndoKey, !undoStack.isEmpty {
            undoStack[undoStack.count - 1] = snap
        } else {
            if undoStack.count >= maxUndo { undoStack.removeFirst() }
            undoStack.append(snap)
        }
        lastUndoKey = coalesceKey
        redoStack.removeAll()
    }

    func undo() {
        guard let s = undoStack.popLast() else { return }
        redoStack.append(.init(layers: layers, background: background, selectedLayerID: selectedLayerID))
        layers = s.layers; background = s.background; selectedLayerID = s.selectedLayerID
        isEditing = false; lastUndoKey = nil; announce("Undo")
    }

    func redo() {
        guard let s = redoStack.popLast() else { return }
        undoStack.append(.init(layers: layers, background: background, selectedLayerID: selectedLayerID))
        layers = s.layers; background = s.background; selectedLayerID = s.selectedLayerID
        isEditing = false; lastUndoKey = nil; announce("Redo")
    }

    // MARK: - Custom Guides

    func addCustomGuide(axis: GuideAxis, position: CGFloat) {
        customGuides.append(CustomGuide(axis: axis, position: position))
        announce("Custom guide added")
    }
    func removeCustomGuide(id: UUID) { customGuides.removeAll { $0.id == id }; announce("Guide removed") }
    func moveCustomGuide(id: UUID, to position: CGFloat) {
        if let i = customGuides.firstIndex(where: { $0.id == id }) { customGuides[i].position = position }
    }

    // MARK: - Background

    func setBackground(_ image: UIImage) { pushUndo(); background = CanvasBackground(image: image) }
    func clearBackground() { pushUndo(); background = nil }
    func updateBackgroundScale(_ scale: CGFloat) { pushUndo(); background?.scale = max(1.0, min(scale, 5.0)) }
    func updateBackgroundOffset(_ offset: CGSize) { pushUndo(); background?.offset = offset }

    // MARK: - Layer CRUD

    func addTextLayer(fontFamily: String = "Playfair Display") {
        pushUndo()
        var layer = TextLayer()
        layer.zIndex = nextZIndex()
        layer.name = "Text \(layers.count + 1)"
        layer.fontFamily = fontFamily
        layers.append(layer)
        selectedLayerID = layer.id
        isEditing = true
    }

    func addImageLayer(_ image: UIImage) {
        pushUndo()
        var layer = ImageLayer(image: image)
        layer.zIndex = nextZIndex()
        layer.name = "Image \(layers.count + 1)"
        layers.append(layer)
        selectedLayerID = layer.id
    }

    func removeLayer(id: UUID) {
        if selectedLayerID == id { isEditing = false }
        layers.removeAll { $0.id == id }
        if selectedLayerID == id { selectedLayerID = nil }
        multiSelectedIDs.remove(id)
        renumberZIndices()
    }

    func removeSelectedLayers() {
        pushUndo()
        if isMultiSelectActive {
            layers.removeAll { multiSelectedIDs.contains($0.id) }
            multiSelectedIDs.removeAll(); isMultiSelectActive = false; isEditing = false
        } else if let id = selectedLayerID {
            removeLayer(id: id)
        }
    }

    // MARK: - Selection

    func selectLayer(id: UUID) {
        if isMultiSelectActive {
            if multiSelectedIDs.contains(id) { multiSelectedIDs.remove(id) }
            else { multiSelectedIDs.insert(id) }
        } else {
            selectedLayerID = id; isEditing = false
        }
    }

    func deselectAll() {
        selectedLayerID = nil; isEditing = false
        if isMultiSelectActive { multiSelectedIDs.removeAll(); isMultiSelectActive = false }
        clearActiveGuides()
    }

    func enterMultiSelect(startingWith id: UUID) {
        isMultiSelectActive = true; multiSelectedIDs.insert(id); selectedLayerID = nil
    }

    // MARK: - Generic mutator

    func updateLayer<T: Layer>(id: UUID, transform: (inout T) -> Void) {
        guard let idx = layers.firstIndex(where: { $0.id == id }),
              var typed = layers[idx] as? T else { return }
        pushUndo()
        transform(&typed)
        layers[idx] = typed
    }

    // MARK: - TextLayer convenience

    func updateText(id: UUID, text: String)                    { updateLayer(id: id) { (l: inout TextLayer) in l.text = text } }
    func updateFont(id: UUID, fontFamily: String)              { updateLayer(id: id) { (l: inout TextLayer) in l.fontFamily = fontFamily } }
    func updateFontSize(id: UUID, fontSize: CGFloat)           { updateLayer(id: id) { (l: inout TextLayer) in l.fontSize = fontSize } }
    func updateColor(id: UUID, color: Color)                   { updateLayer(id: id) { (l: inout TextLayer) in l.textColor = color } }
    func updateAlignment(id: UUID, alignment: TextAlignment)   { updateLayer(id: id) { (l: inout TextLayer) in l.alignment = alignment } }
    func updateLetterSpacing(id: UUID, spacing: CGFloat)       { updateLayer(id: id) { (l: inout TextLayer) in l.letterSpacing = spacing } }

    // MARK: - Transform

    func updatePosition(id: UUID, position: CGSize) {
        guard var layer = layers.first(where: { $0.id == id }) else { return }
        pushUndo(coalesceKey: "pos-\(id)")
        if canvasSize == .zero { layer.position = position; replaceLayer(layer); return }

        let size = boundingSize(for: layer)
        let others = otherLayerGeometries(excluding: id)
        var (snapped, guides) = AlignmentEngine.snapPosition(
            position, layerSize: size, otherLayers: others,
            canvasSize: canvasSize, threshold: CGFloat(snapThreshold)
        )

        // Snap to custom guides
        for g in customGuides {
            if g.axis == .vertical, abs(snapped.width - g.position) <= CGFloat(snapThreshold) {
                snapped.width = g.position
                guides.append(Guide(axis: .vertical, position: g.position, kind: .layerEdge))
            }
            if g.axis == .horizontal, abs(snapped.height - g.position) <= CGFloat(snapThreshold) {
                snapped.height = g.position
                guides.append(Guide(axis: .horizontal, position: g.position, kind: .layerEdge))
            }
        }

        let px = CGSize(width: (snapped.width * 2).rounded() / 2, height: (snapped.height * 2).rounded() / 2)
        layer.position = clampedPosition(px, layerSize: size)
        replaceLayer(layer)
        updateActiveGuides(guides)
    }

    func updateScale(id: UUID, scale: CGFloat) {
        pushUndo(coalesceKey: "scl-\(id)")
        if var l = layers.first(where: { $0.id == id }) { l.scale = max(0.3, min(5.0, scale)); replaceLayer(l) }
    }

    func updateRotation(id: UUID, rotation: Angle) {
        pushUndo(coalesceKey: "rot-\(id)")
        if var l = layers.first(where: { $0.id == id }) { l.rotation = rotation; replaceLayer(l) }
    }

    // MARK: - Lock / Visibility / Z-order

    func toggleLock(id: UUID) {
        pushUndo()
        if var l = layers.first(where: { $0.id == id }) {
            l.isLocked.toggle(); replaceLayer(l)
            announce(l.isLocked ? "\(l.name) locked" : "\(l.name) unlocked")
        }
    }

    func toggleVisibility(id: UUID) {
        pushUndo()
        if var l = layers.first(where: { $0.id == id }) {
            l.isVisible.toggle(); replaceLayer(l)
            announce(l.isVisible ? "\(l.name) visible" : "\(l.name) hidden")
        }
    }

    func moveLayer(from source: IndexSet, to destination: Int) {
        pushUndo(); layers.move(fromOffsets: source, toOffset: destination); renumberZIndices()
    }

    func resetLayerTransform(id: UUID) {
        pushUndo()
        if var l = layers.first(where: { $0.id == id }) {
            l.position = .zero; l.scale = 1.0; l.rotation = .zero; replaceLayer(l)
        }
    }

    func nudgeSelected(dx: CGFloat, dy: CGFloat) {
        pushUndo()
        guard let id = selectedLayerID, var l = layers.first(where: { $0.id == id }), !l.isLocked else { return }
        l.position = CGSize(width: l.position.width + dx, height: l.position.height + dy)
        replaceLayer(l)
    }

    func batchMoveSelectedLayers(by delta: CGSize) {
        pushUndo()
        for id in multiSelectedIDs {
            if var l = layers.first(where: { $0.id == id }) {
                l.position = CGSize(width: l.position.width + delta.width, height: l.position.height + delta.height)
                replaceLayer(l)
            }
        }
    }

    // MARK: - Computed

    var sortedLayers: [any Layer] { layers.sorted { $0.zIndex < $1.zIndex } }
    var selectedTextLayer: TextLayer? { selectedLayerID.flatMap { id in layers.first(where: { $0.id == id }) as? TextLayer } }

    // MARK: - Private

    private func boundingSize(for layer: any Layer) -> CGSize {
        if let t = layer as? TextLayer {
            return CGSize(width: min(t.fontSize * CGFloat(max(t.text.count, 3)) * 0.6, 300), height: t.fontSize * 1.4)
        } else if let img = layer as? ImageLayer {
            return CGSize(width: 200, height: 200 / img.aspectRatio)
        }
        return CGSize(width: 100, height: 40)
    }

    private func otherLayerGeometries(excluding id: UUID) -> [LayerGeometry] {
        layers.filter { $0.id != id && $0.isVisible }.map { LayerGeometry(position: $0.position, size: boundingSize(for: $0)) }
    }

    private func nextZIndex() -> Int { (layers.map(\.zIndex).max() ?? -1) + 1 }
    private func renumberZIndices() { for i in layers.indices { layers[i].zIndex = i } }
    private func replaceLayer(_ layer: some Layer) {
        guard let i = layers.firstIndex(where: { $0.id == layer.id }) else { return }
        layers[i] = layer
    }

    private func clampedPosition(_ p: CGSize, layerSize: CGSize) -> CGSize {
        guard canvasSize.width > 0 else { return p }
        let m = CGSize(width: max(layerSize.width * 0.25, 30), height: max(layerSize.height * 0.25, 30))
        let maxX = canvasSize.width / 2 + layerSize.width / 2 - m.width
        let maxY = canvasSize.height / 2 + layerSize.height / 2 - m.height
        return CGSize(width: min(max(p.width, -maxX), maxX), height: min(max(p.height, -maxY), maxY))
    }
}
