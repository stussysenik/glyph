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
    var fontFamily: String = "Playfair Display"
    var fontSize: CGFloat = 64
    var textColor: Color = .black
    var alignment: TextAlignment = .center
    var letterSpacing: CGFloat = 0
}

// MARK: - ImageLayer

/// A raster image overlay — draggable, resizable, rotatable.
struct ImageLayer: @unchecked Sendable, Layer {
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
