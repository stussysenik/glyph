import SwiftUI

/// Owns the canvas state: all text overlays, selection, and editing mode.
@Observable
final class CanvasViewModel {
    var overlays: [TextOverlay] = []
    var selectedOverlayID: UUID?
    var isEditing: Bool = false

    /// The currently selected overlay, if any.
    var selectedOverlay: TextOverlay? {
        guard let id = selectedOverlayID else { return nil }
        return overlays.first { $0.id == id }
    }

    /// Index of the selected overlay for mutation.
    private var selectedIndex: Int? {
        guard let id = selectedOverlayID else { return nil }
        return overlays.firstIndex { $0.id == id }
    }

    // MARK: - Actions

    /// Add a new text overlay at center. Returns the new overlay's ID.
    @discardableResult
    func addOverlay(fontFamily: String = "Playfair Display") -> UUID {
        let overlay = TextOverlay(fontFamily: fontFamily)
        overlays.append(overlay)
        selectedOverlayID = overlay.id
        isEditing = true
        return overlay.id
    }

    func selectOverlay(id: UUID?) {
        selectedOverlayID = id
        if id == nil { isEditing = false }
    }

    func deselectAll() {
        selectedOverlayID = nil
        isEditing = false
    }

    func removeOverlay(id: UUID) {
        overlays.removeAll { $0.id == id }
        if selectedOverlayID == id {
            selectedOverlayID = nil
            isEditing = false
        }
    }

    func removeSelected() {
        guard let id = selectedOverlayID else { return }
        removeOverlay(id: id)
    }

    // MARK: - Update selected overlay properties

    func updateText(_ text: String) {
        guard let i = selectedIndex else { return }
        overlays[i].text = text
    }

    func updateFont(_ family: String) {
        guard let i = selectedIndex else { return }
        overlays[i].fontFamily = family
    }

    func updateFontSize(_ size: CGFloat) {
        guard let i = selectedIndex else { return }
        overlays[i].fontSize = size
    }

    func updateColor(_ color: Color) {
        guard let i = selectedIndex else { return }
        overlays[i].textColor = color
    }

    func updateAlignment(_ alignment: TextAlignment) {
        guard let i = selectedIndex else { return }
        overlays[i].alignment = alignment
    }

    func updateLetterSpacing(_ spacing: CGFloat) {
        guard let i = selectedIndex else { return }
        overlays[i].letterSpacing = spacing
    }

    func updatePosition(_ position: CGSize, for id: UUID) {
        guard let i = overlays.firstIndex(where: { $0.id == id }) else { return }
        overlays[i].position = position
    }

    func updateScale(_ scale: CGFloat, for id: UUID) {
        guard let i = overlays.firstIndex(where: { $0.id == id }) else { return }
        overlays[i].scale = scale
    }

    func updateRotation(_ rotation: Angle, for id: UUID) {
        guard let i = overlays.firstIndex(where: { $0.id == id }) else { return }
        overlays[i].rotation = rotation
    }
}
