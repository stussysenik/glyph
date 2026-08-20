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
    var effects: TextEffects = TextEffects()
}

// MARK: - TextEffects

/// Instagram-style text treatments layered onto a TextLayer.
/// Each treatment is "off" at its zero value (nil highlight, zero stroke
/// width, zero shadow radius), so a default `TextEffects` renders identically
/// to plain text. The text fill color lives on `TextLayer.textColor`.
struct TextEffects: Equatable, Sendable {
    /// Rounded swatch drawn behind the text. `nil` = no highlight.
    var highlightColor: Color? = nil
    /// Horizontal / vertical inset of the highlight box around the text bounds.
    var highlightPadding: CGSize = CGSize(width: 18, height: 10)
    /// Corner radius of the highlight box, in points.
    var highlightCornerRadius: CGFloat = 12
    /// Outline color. Only drawn when `strokeWidth > 0`.
    var strokeColor: Color = .white
    /// Outline thickness in points. `0` = no outline.
    var strokeWidth: CGFloat = 0
    /// Shadow / glow color. Only drawn when `shadowRadius > 0`.
    var shadowColor: Color = .black
    /// Blur radius of the shadow / glow. `0` = no shadow.
    var shadowRadius: CGFloat = 0
    /// Shadow offset. `.zero` produces an even glow (neon).
    var shadowOffset: CGSize = .zero
    /// Shadow opacity, 0...1.
    var shadowOpacity: CGFloat = 0.5

    /// True when no visible treatment is active.
    var isPlain: Bool {
        highlightColor == nil && strokeWidth == 0 && shadowRadius == 0
    }
}

// MARK: - TextStyle

/// One-tap Instagram-style text treatments surfaced as chips in the editor.
/// Applying a style replaces `TextEffects` but never touches the fill color,
/// so the user's chosen text color is preserved across style switches.
enum TextStyle: String, CaseIterable, Identifiable, Sendable {
    case plain, highlight, outline, neon, shadow

    var id: String { rawValue }

    var label: String {
        switch self {
        case .plain:     return "Plain"
        case .highlight: return "Highlight"
        case .outline:   return "Outline"
        case .neon:      return "Neon"
        case .shadow:    return "Shadow"
        }
    }

    var effects: TextEffects {
        switch self {
        case .plain:
            return TextEffects()
        case .highlight:
            return TextEffects(highlightColor: .white)
        case .outline:
            return TextEffects(strokeColor: .black, strokeWidth: 4)
        case .neon:
            return TextEffects(shadowColor: .cyan, shadowRadius: 16, shadowOpacity: 0.9)
        case .shadow:
            return TextEffects(shadowColor: .black, shadowRadius: 8,
                               shadowOffset: CGSize(width: 0, height: 3), shadowOpacity: 0.55)
        }
    }
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
