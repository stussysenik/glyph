import SwiftUI

/// A single text element on the canvas — position, style, and transform state.
struct TextOverlay: Identifiable {
    let id: UUID
    var text: String
    var fontFamily: String
    var fontSize: CGFloat
    var textColor: Color
    var alignment: TextAlignment
    var letterSpacing: CGFloat
    var position: CGSize
    var scale: CGFloat
    var rotation: Angle

    init(
        id: UUID = UUID(),
        text: String = "Hello",
        fontFamily: String = "Playfair Display",
        fontSize: CGFloat = 64,
        textColor: Color = .black,
        alignment: TextAlignment = .center,
        letterSpacing: CGFloat = 0,
        position: CGSize = .zero,
        scale: CGFloat = 1.0,
        rotation: Angle = .zero
    ) {
        self.id = id
        self.text = text
        self.fontFamily = fontFamily
        self.fontSize = fontSize
        self.textColor = textColor
        self.alignment = alignment
        self.letterSpacing = letterSpacing
        self.position = position
        self.scale = scale
        self.rotation = rotation
    }
}
