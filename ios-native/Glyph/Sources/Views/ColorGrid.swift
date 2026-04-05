import SwiftUI

private typealias DS = GlyphDesignSystem

/// 4×4 grid of preset colors — curated for Instagram Stories.
struct ColorGrid: View {
    @Binding var selectedColor: Color
    @Environment(HapticsService.self) private var haptics

    private static let presets: [(color: Color, name: String)] = [
        (.black,                "Black"),
        (Color(hex: 0x424242), "Dark grey"),
        (Color(hex: 0x9E9E9E), "Medium grey"),
        (Color(hex: 0xE0E0E0), "Light grey"),
        (.white,                "White"),
        (Color(hex: 0x1A1A1A), "Near black"),
        (Color(hex: 0xFF3B30), "Red"),
        (Color(hex: 0xFF8A65), "Coral"),
        (Color(hex: 0xFFD54F), "Yellow"),
        (Color(hex: 0x34C759), "Green"),
        (Color(hex: 0x4DD0E1), "Cyan"),
        (Color(hex: 0x64B5F6), "Light blue"),
        (Color(hex: 0x7986CB), "Indigo"),
        (Color(hex: 0xBA68C8), "Purple"),
        (Color(hex: 0xF06292), "Pink"),
        (Color(hex: 0xA1887F), "Brown"),
    ]

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 8)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(Array(Self.presets.enumerated()), id: \.offset) { _, entry in
                Button {
                    selectedColor = entry.color
                    haptics.selectionChanged()
                } label: {
                    Circle()
                        .fill(entry.color)
                        .frame(width: 32, height: 32)
                        .overlay {
                            if entry.color == .white {
                                Circle()
                                    .stroke(DS.Color.border, lineWidth: 1)
                            }
                        }
                        .overlay {
                            if selectedColor == entry.color {
                                Circle()
                                    .stroke(DS.Color.accent, lineWidth: 2.5)
                                    .padding(-3)
                            }
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(entry.name)
            }
        }
    }
}
