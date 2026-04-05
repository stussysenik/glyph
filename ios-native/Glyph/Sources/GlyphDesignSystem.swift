import SwiftUI

/// Glyph's design system — light typographic theme.
/// iA Writer clarity × Things depth × Heron Preston industrial edge.
///
/// This is the single source of truth for all visual tokens.
/// No raw color/font/spacing values anywhere else in the codebase.
enum GlyphDesignSystem {

    // MARK: - Color

    enum Color {
        static let canvas       = SwiftUI.Color(hex: 0xFFFFFF)
        static let surface      = SwiftUI.Color(hex: 0xF7F7F7)
        static let surfaceAlt   = SwiftUI.Color(hex: 0xEBEBEB)
        static let accent       = SwiftUI.Color(hex: 0x39FF14)
        static let accentSubtle = SwiftUI.Color(hex: 0x39FF14).opacity(0.15)
        static let textPrimary  = SwiftUI.Color(hex: 0x1A1A1A)
        static let textSecondary = SwiftUI.Color(hex: 0x6B6B6B)
        static let textTertiary = SwiftUI.Color(hex: 0xB0B0B0)
        static let border       = SwiftUI.Color(hex: 0xE0E0E0)
        static let borderSubtle = SwiftUI.Color(hex: 0xF0F0F0)
        static let error        = SwiftUI.Color(hex: 0xFF3B30)
        static let success      = SwiftUI.Color(hex: 0x34C759)
    }

    // MARK: - Typography

    enum Typography {
        static let display = Font.system(size: 28, weight: .bold)
        static let title   = Font.system(size: 20, weight: .semibold)
        static let body    = Font.system(size: 16, weight: .regular)
        static let caption = Font.system(size: 13, weight: .regular)
        /// Monospaced uppercase label — the Heron Preston / iA Writer signature.
        static let label   = Font.system(size: 11, weight: .medium, design: .monospaced)
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
