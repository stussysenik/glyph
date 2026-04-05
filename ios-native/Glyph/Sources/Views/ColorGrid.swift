import SwiftUI

private typealias DS = GlyphDesignSystem

/// 4×4 grid of preset colors — curated for Instagram Stories.
struct ColorGrid: View {
    @Binding var selectedColor: Color

    private static let presets: [Color] = [
        .black,
        Color(hex: 0x424242),
        Color(hex: 0x9E9E9E),
        Color(hex: 0xE0E0E0),
        .white,
        Color(hex: 0x1A1A1A),
        Color(hex: 0xFF3B30),
        Color(hex: 0xFF8A65),
        Color(hex: 0xFFD54F),
        Color(hex: 0x34C759),
        Color(hex: 0x4DD0E1),
        Color(hex: 0x64B5F6),
        Color(hex: 0x7986CB),
        Color(hex: 0xBA68C8),
        Color(hex: 0xF06292),
        Color(hex: 0xA1887F),
    ]

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 8)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(Array(Self.presets.enumerated()), id: \.offset) { _, color in
                Circle()
                    .fill(color)
                    .frame(width: 32, height: 32)
                    .overlay {
                        if color == .white {
                            Circle()
                                .stroke(DS.Color.border, lineWidth: 1)
                        }
                    }
                    .overlay {
                        if selectedColor == color {
                            Circle()
                                .stroke(DS.Color.accent, lineWidth: 2.5)
                                .padding(-3)
                        }
                    }
                    .onTapGesture {
                        selectedColor = color
                        UISelectionFeedbackGenerator().selectionChanged()
                    }
            }
        }
    }
}
