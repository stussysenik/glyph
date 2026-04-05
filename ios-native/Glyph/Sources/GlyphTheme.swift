import SwiftUI

/// Glyph's dark, minimal theme — ported from the Flutter version.
enum GlyphTheme {
    static let background = Color(red: 0.10, green: 0.10, blue: 0.10)  // #1A1A1A
    static let surface = Color(red: 0.14, green: 0.14, blue: 0.14)     // #242424
    static let surfaceLight = Color(red: 0.18, green: 0.18, blue: 0.18) // #2E2E2E
    static let textPrimary = Color.white
    static let textSecondary = Color(red: 0.56, green: 0.56, blue: 0.58) // #8E8E93
    static let accent = Color(red: 0.42, green: 0.39, blue: 1.0)       // #6C63FF
    static let accentLight = Color(red: 0.55, green: 0.51, blue: 1.0)  // #8B83FF
    static let divider = Color(red: 0.23, green: 0.23, blue: 0.23)     // #3A3A3A
    static let error = Color(red: 1.0, green: 0.42, blue: 0.42)        // #FF6B6B
    static let success = Color(red: 0.30, green: 0.85, blue: 0.39)     // #4CD964
}
