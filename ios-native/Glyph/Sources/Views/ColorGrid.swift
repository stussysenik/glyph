import SwiftUI

/// 4x4 grid of preset colors — curated for Instagram Stories.
struct ColorGrid: View {
    @Binding var selectedColor: Color

    /// 16 preset colors matching the Flutter theme.
    private static let presets: [Color] = [
        .white,
        Color(red: 0.96, green: 0.96, blue: 0.96),  // #F5F5F5
        Color(red: 0.88, green: 0.88, blue: 0.88),  // #E0E0E0
        Color(red: 0.62, green: 0.62, blue: 0.62),  // #9E9E9E
        Color(red: 0.26, green: 0.26, blue: 0.26),  // #424242
        .black,
        Color(red: 1.00, green: 0.42, blue: 0.42),  // #FF6B6B
        Color(red: 1.00, green: 0.54, blue: 0.40),  // #FF8A65
        Color(red: 1.00, green: 0.84, blue: 0.31),  // #FFD54F
        Color(red: 0.51, green: 0.78, blue: 0.52),  // #81C784
        Color(red: 0.30, green: 0.82, blue: 0.88),  // #4DD0E1
        Color(red: 0.39, green: 0.71, blue: 0.96),  // #64B5F6
        Color(red: 0.47, green: 0.53, blue: 0.80),  // #7986CB
        Color(red: 0.73, green: 0.41, blue: 0.78),  // #BA68C8
        Color(red: 0.94, green: 0.38, blue: 0.57),  // #F06292
        Color(red: 0.63, green: 0.53, blue: 0.50),  // #A1887F
    ]

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 8)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(Array(Self.presets.enumerated()), id: \.offset) { _, color in
                Circle()
                    .fill(color)
                    .frame(width: 32, height: 32)
                    .overlay {
                        if selectedColor == color {
                            Circle()
                                .stroke(GlyphTheme.accent, lineWidth: 2.5)
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
