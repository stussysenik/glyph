import SwiftUI

// MARK: - StylePreset

/// A named snapshot of text styling that can be applied to any TextLayer.
/// Built-in presets are read-only; user presets are persisted via PresetStore.
struct StylePreset: Identifiable, Codable, Sendable {
    var id: UUID
    var name: String
    var fontFamily: String
    var fontSize: CGFloat
    var textColor: CodableColor
    var letterSpacing: CGFloat
    var alignment: CodableAlignment
    var isBuiltIn: Bool

    /// Applies all preset properties to the given layer via the CanvasViewModel.
    func apply(to vm: CanvasViewModel, layerID: UUID) {
        vm.updateFont(id: layerID, fontFamily: fontFamily)
        vm.updateFontSize(id: layerID, fontSize: fontSize)
        vm.updateColor(id: layerID, color: textColor.swiftUIColor)
        vm.updateLetterSpacing(id: layerID, spacing: letterSpacing)
        vm.updateAlignment(id: layerID, alignment: alignment.textAlignment)
    }

    /// Creates a new user preset by capturing the current state of a TextLayer.
    static func from(layer: TextLayer, name: String) -> StylePreset {
        StylePreset(
            id: UUID(),
            name: name,
            fontFamily: layer.fontFamily,
            fontSize: layer.fontSize,
            textColor: CodableColor(layer.textColor),
            letterSpacing: layer.letterSpacing,
            alignment: CodableAlignment(layer.alignment),
            isBuiltIn: false
        )
    }
}

// MARK: - Built-in Presets

extension StylePreset {
    /// Factory presets shipped with the app. IDs are stable so the store can
    /// always filter them out by `isBuiltIn` rather than matching by ID.
    static let builtIns: [StylePreset] = [
        StylePreset(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            name: "Editorial Bold",
            fontFamily: "Playfair Display",
            fontSize: 48,
            textColor: CodableColor(r: 0, g: 0, b: 0),
            letterSpacing: 0,
            alignment: .leading,
            isBuiltIn: true
        ),
        StylePreset(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            name: "Caption Minimal",
            fontFamily: "Space Grotesk",
            fontSize: 16,
            textColor: CodableColor(r: 0.4, g: 0.4, b: 0.4),
            letterSpacing: 1.5,
            alignment: .center,
            isBuiltIn: true
        ),
        StylePreset(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
            name: "Display Statement",
            fontFamily: "Archivo Black",
            fontSize: 64,
            textColor: CodableColor(r: 0, g: 0, b: 0),
            letterSpacing: -0.5,
            alignment: .center,
            isBuiltIn: true
        ),
        StylePreset(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!,
            name: "Handwritten Note",
            fontFamily: "Caveat",
            fontSize: 36,
            textColor: CodableColor(r: 0.2, g: 0.2, b: 0.2),
            letterSpacing: 0.5,
            alignment: .leading,
            isBuiltIn: true
        ),
        StylePreset(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000005")!,
            name: "Serif Classic",
            fontFamily: "DM Serif Display",
            fontSize: 40,
            textColor: CodableColor(r: 0.1, g: 0.1, b: 0.1),
            letterSpacing: 0.3,
            alignment: .center,
            isBuiltIn: true
        ),
    ]
}

// MARK: - CodableColor

/// Codable wrapper around RGBA components, bridging SwiftUI Color ↔ JSON.
/// Uses UIColor for reliable component extraction from SwiftUI Color.
struct CodableColor: Codable, Sendable {
    var red: CGFloat
    var green: CGFloat
    var blue: CGFloat
    var alpha: CGFloat

    init(r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat = 1.0) {
        red = r; green = g; blue = b; alpha = a
    }

    /// Extracts RGBA components from a SwiftUI Color via UIColor bridge.
    init(_ swiftUIColor: Color) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(swiftUIColor).getRed(&r, green: &g, blue: &b, alpha: &a)
        red = r; green = g; blue = b; alpha = a
    }

    /// Reconstructs a SwiftUI Color from stored components.
    var swiftUIColor: Color {
        Color(red: Double(red), green: Double(green), blue: Double(blue), opacity: Double(alpha))
    }
}

// MARK: - CodableAlignment

/// Codable wrapper for SwiftUI TextAlignment, which is not itself Codable.
enum CodableAlignment: String, Codable, Sendable {
    case leading, center, trailing

    var textAlignment: TextAlignment {
        switch self {
        case .leading:  return .leading
        case .center:   return .center
        case .trailing: return .trailing
        }
    }

    init(_ alignment: TextAlignment) {
        switch alignment {
        case .leading:  self = .leading
        case .center:   self = .center
        case .trailing: self = .trailing
        }
    }
}
