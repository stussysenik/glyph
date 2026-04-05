import SwiftUI

/// Bottom sheet with styling controls for the selected overlay.
struct StyleControlsView: View {
    @Environment(CanvasViewModel.self) private var canvas

    var body: some View {
        if let overlay = canvas.selectedOverlay {
            VStack(spacing: 20) {
                // Font Size
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Size")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(GlyphTheme.textSecondary)
                        Spacer()
                        Text("\(Int(overlay.fontSize))pt")
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(GlyphTheme.textSecondary)
                    }
                    Slider(
                        value: Binding(
                            get: { overlay.fontSize },
                            set: { canvas.updateFontSize($0) }
                        ),
                        in: 24...200,
                        step: 1
                    )
                    .tint(GlyphTheme.accent)
                }

                // Letter Spacing
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Spacing")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(GlyphTheme.textSecondary)
                        Spacer()
                        Text(String(format: "%.1f", overlay.letterSpacing))
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(GlyphTheme.textSecondary)
                    }
                    Slider(
                        value: Binding(
                            get: { overlay.letterSpacing },
                            set: { canvas.updateLetterSpacing($0) }
                        ),
                        in: -5...20,
                        step: 0.5
                    )
                    .tint(GlyphTheme.accent)
                }

                // Alignment
                HStack(spacing: 12) {
                    Text("Align")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(GlyphTheme.textSecondary)
                    Spacer()
                    ForEach(
                        [(TextAlignment.leading, "text.alignleft"),
                         (.center, "text.aligncenter"),
                         (.trailing, "text.alignright")],
                        id: \.0.hashValue
                    ) { alignment, icon in
                        Button {
                            canvas.updateAlignment(alignment)
                            UISelectionFeedbackGenerator().selectionChanged()
                        } label: {
                            Image(systemName: icon)
                                .font(.body)
                                .foregroundStyle(
                                    overlay.alignment == alignment
                                        ? GlyphTheme.accent
                                        : GlyphTheme.textSecondary
                                )
                                .frame(width: 40, height: 36)
                                .background(
                                    overlay.alignment == alignment
                                        ? GlyphTheme.accent.opacity(0.15)
                                        : Color.clear,
                                    in: RoundedRectangle(cornerRadius: 8)
                                )
                        }
                    }
                }

                // Color Grid
                VStack(alignment: .leading, spacing: 8) {
                    Text("Color")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(GlyphTheme.textSecondary)
                    ColorGrid(
                        selectedColor: Binding(
                            get: { overlay.textColor },
                            set: { canvas.updateColor($0) }
                        )
                    )
                }
            }
            .padding(20)
        }
    }
}
