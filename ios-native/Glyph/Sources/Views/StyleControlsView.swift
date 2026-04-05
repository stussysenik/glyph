import SwiftUI

private typealias DS = GlyphDesignSystem

/// Bottom sheet with styling controls for the selected text layer.
struct StyleControlsView: View {
    @Environment(CanvasViewModel.self) private var canvas

    var body: some View {
        if let overlay = canvas.selectedTextLayer {
            VStack(spacing: DS.Spacing.xl) {
                VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                    HStack {
                        Text("SIZE")
                            .font(DS.Typography.label)
                            .tracking(1.5)
                            .foregroundStyle(DS.Color.textTertiary)
                        Spacer()
                        Text("\(Int(overlay.fontSize))pt")
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(DS.Color.textSecondary)
                    }
                    Slider(
                        value: Binding(
                            get: { overlay.fontSize },
                            set: { canvas.updateFontSize(id: overlay.id, fontSize: $0) }
                        ),
                        in: 24...200,
                        step: 1
                    )
                    .tint(DS.Color.accent)
                }

                VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                    HStack {
                        Text("SPACING")
                            .font(DS.Typography.label)
                            .tracking(1.5)
                            .foregroundStyle(DS.Color.textTertiary)
                        Spacer()
                        Text(String(format: "%.1f", overlay.letterSpacing))
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(DS.Color.textSecondary)
                    }
                    Slider(
                        value: Binding(
                            get: { overlay.letterSpacing },
                            set: { canvas.updateLetterSpacing(id: overlay.id, spacing: $0) }
                        ),
                        in: -5...20,
                        step: 0.5
                    )
                    .tint(DS.Color.accent)
                }

                HStack(spacing: DS.Spacing.md) {
                    Text("ALIGN")
                        .font(DS.Typography.label)
                        .tracking(1.5)
                        .foregroundStyle(DS.Color.textTertiary)
                    Spacer()
                    ForEach(
                        [(TextAlignment.leading, "text.alignleft"),
                         (.center, "text.aligncenter"),
                         (.trailing, "text.alignright")],
                        id: \.0.hashValue
                    ) { alignment, icon in
                        Button {
                            canvas.updateAlignment(id: overlay.id, alignment: alignment)
                            UISelectionFeedbackGenerator().selectionChanged()
                        } label: {
                            Image(systemName: icon)
                                .font(.body)
                                .foregroundStyle(
                                    overlay.alignment == alignment
                                        ? DS.Color.accent
                                        : DS.Color.textSecondary
                                )
                                .frame(width: 40, height: 36)
                                .background(
                                    overlay.alignment == alignment
                                        ? DS.Color.accent.opacity(0.15)
                                        : SwiftUI.Color.clear,
                                    in: RoundedRectangle(cornerRadius: DS.Radius.sm)
                                )
                        }
                    }
                }

                VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                    Text("COLOR")
                        .font(DS.Typography.label)
                        .tracking(1.5)
                        .foregroundStyle(DS.Color.textTertiary)
                    ColorGrid(
                        selectedColor: Binding(
                            get: { overlay.textColor },
                            set: { canvas.updateColor(id: overlay.id, color: $0) }
                        )
                    )
                }
            }
            .padding(DS.Spacing.xl)
        }
    }
}
