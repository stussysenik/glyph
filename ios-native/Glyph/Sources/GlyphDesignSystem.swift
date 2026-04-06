import SwiftUI

/// Glyph's design system — light typographic theme.
/// iA Writer clarity × Things depth × Heron Preston industrial edge.
///
/// This is the single source of truth for all visual tokens.
/// No raw color/font/spacing values anywhere else in the codebase.
enum GlyphDesignSystem {

    // MARK: - Color

    /// Default accent hex — neon green.
    static let defaultAccentHex: UInt = 0x39FF14

    enum Color {
        static let canvas       = SwiftUI.Color(hex: 0xFFFFFF)
        static let surface      = SwiftUI.Color(hex: 0xF7F7F7)
        static let surfaceAlt   = SwiftUI.Color(hex: 0xEBEBEB)

        /// Accent color — reads the user's stored preference (falls back to neon green).
        static var accent: SwiftUI.Color {
            let stored = UserDefaults.standard.integer(forKey: "app.accentColorHex")
            return stored == 0
                ? SwiftUI.Color(hex: GlyphDesignSystem.defaultAccentHex)
                : SwiftUI.Color(hex: UInt(stored))
        }
        static var accentSubtle: SwiftUI.Color { accent.opacity(0.15) }

        static let textPrimary  = SwiftUI.Color(hex: 0x1A1A1A)
        static let textSecondary = SwiftUI.Color(hex: 0x595959)  // 5.9:1 on surface — WCAG AA
        static let textTertiary = SwiftUI.Color(hex: 0x757575)   // 4.6:1 on surface — WCAG AA
        static let border       = SwiftUI.Color(hex: 0xE0E0E0)
        static let borderSubtle = SwiftUI.Color(hex: 0xF0F0F0)
        static let error        = SwiftUI.Color(hex: 0xFF3B30)
        static let success      = SwiftUI.Color(hex: 0x34C759)
    }

    // MARK: - Typography
    // Uses semantic text styles so UI chrome scales with Dynamic Type.
    // Canvas text (user-controlled font size) is NOT affected.

    enum Typography {
        static let display = Font.title.bold()
        static let title   = Font.title3.weight(.semibold)
        static let body    = Font.body
        static let caption = Font.caption
        /// Monospaced uppercase label — the Heron Preston / iA Writer signature.
        static let label   = Font.caption2.monospaced().weight(.medium)
    }

    // MARK: - Spacing

    enum Spacing {
        static let xs:  CGFloat = 4
        static let sm:  CGFloat = 8
        static let md:  CGFloat = 12
        static let lg:  CGFloat = 16
        static let xl:  CGFloat = 24
        static let xxl: CGFloat = 32
    }

    // MARK: - Radius

    enum Radius {
        static let sm:   CGFloat = 6
        static let md:   CGFloat = 10
        static let lg:   CGFloat = 14
        static let xl:   CGFloat = 20
        static let pill: CGFloat = 999
    }

    // MARK: - Shadow

    enum Shadow {
        static func soft(_ content: some View) -> some View {
            content.shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
        }
        static func medium(_ content: some View) -> some View {
            content.shadow(color: .black.opacity(0.10), radius: 8, x: 0, y: 4)
        }
        static func sheet(_ content: some View) -> some View {
            content.shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: -4)
        }
    }
}

// MARK: - Color Hex Initializer

extension Color {
    init(hex: UInt, opacity: Double = 1.0) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}
