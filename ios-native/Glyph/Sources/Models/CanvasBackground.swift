import SwiftUI

/// The full-bleed 9:16 background behind all layers.
/// Stores the source image plus interactive pan/zoom state.
struct CanvasBackground: @unchecked Sendable {
    var image: UIImage
    /// Current scale applied by the user's pinch gesture (clamped 1x–5x)
    var scale: CGFloat = 1.0
    /// Cumulative pan offset from the image's natural center
    var offset: CGSize = .zero

    init(image: UIImage) {
        self.image = image
    }
}
