import SwiftUI

private typealias DS = GlyphDesignSystem

/// Color picker grid with preset colors and a recent-colors row.
/// Recent colors track what the user has actually used, making
/// repeated color selection fast — one tap instead of scanning 16.
struct ColorGrid: View {
    @Binding var selectedColor: Color
    @Environment(HapticsService.self) private var haptics

    /// Hex strings of recently used colors (most recent first, max 8).
    var recentColorHexes: [String] = []
    /// Called when a color is selected so the caller can track recents.
    var onColorUsed: ((String) -> Void)? = nil

    private static let presets: [(color: Color, name: String, hex: String)] = [
        (.black,                "Black",       "000000"),
        (Color(hex: 0x424242), "Dark grey",   "424242"),
        (Color(hex: 0x9E9E9E), "Medium grey", "9E9E9E"),
        (Color(hex: 0xE0E0E0), "Light grey",  "E0E0E0"),
        (.white,                "White",       "FFFFFF"),
        (Color(hex: 0x1A1A1A), "Near black",  "1A1A1A"),
        (Color(hex: 0xFF3B30), "Red",         "FF3B30"),
        (Color(hex: 0xFF8A65), "Coral",       "FF8A65"),
        (Color(hex: 0xFFD54F), "Yellow",      "FFD54F"),
        (Color(hex: 0x34C759), "Green",       "34C759"),
        (Color(hex: 0x4DD0E1), "Cyan",        "4DD0E1"),
        (Color(hex: 0x64B5F6), "Light blue",  "64B5F6"),
        (Color(hex: 0x7986CB), "Indigo",      "7986CB"),
        (Color(hex: 0xBA68C8), "Purple",      "BA68C8"),
        (Color(hex: 0xF06292), "Pink",        "F06292"),
        (Color(hex: 0xA1887F), "Brown",       "A1887F"),
    ]

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 8)

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            // Recent colors row (only if any exist)
            if !recentColorHexes.isEmpty {
                HStack(spacing: DS.Spacing.sm) {
                    Text("RECENT")
                        .font(DS.Typography.label)
                        .tracking(1)
                        .foregroundStyle(DS.Color.textTertiary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(recentColorHexes, id: \.self) { hex in
                                let color = Color(hex: UInt(hex, radix: 16) ?? 0)
                                Button {
                                    selectedColor = color
                                    haptics.selectionChanged()
                                } label: {
                                    Circle()
                                        .fill(color)
                                        .frame(width: 28, height: 28)
                                        .overlay {
                                            if selectedColor == color {
                                                Circle()
                                                    .stroke(DS.Color.accent, lineWidth: 2)
                                                    .padding(-2)
                                            }
                                        }
                                }
                                .frame(width: 44, height: 36)
                                .contentShape(Circle())
                                .accessibilityLabel("Recent color")
                            }
                        }
                    }
                }
            }

            // Preset grid
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(Array(Self.presets.enumerated()), id: \.offset) { _, entry in
                    Button {
                        selectedColor = entry.color
                        onColorUsed?(entry.hex)
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
                    .frame(width: 44, height: 44)
                    .contentShape(Circle())
                    .accessibilityLabel(entry.name)
                    .accessibilityAddTraits(selectedColor == entry.color ? [.isSelected] : [])
                }
            }
        }
    }
}
