import SwiftUI

private typealias DS = GlyphDesignSystem

/// Bottom sheet with styling controls for the selected text layer.
struct StyleControlsView: View {
    @Environment(CanvasViewModel.self) private var canvas
    @Environment(PresetStore.self) private var presetStore
    @Environment(HapticsService.self) private var haptics
    @Environment(SettingsViewModel.self) private var settings

    @State private var showPresets = false

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
                    .accessibilityLabel("Font size")
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
                    .accessibilityLabel("Letter spacing")
                }

                HStack(spacing: DS.Spacing.md) {
                    Text("ALIGN")
                        .font(DS.Typography.label)
                        .tracking(1.5)
                        .foregroundStyle(DS.Color.textTertiary)
                    Spacer()
                    ForEach(
                        [(TextAlignment.leading, "text.alignleft", "Align left"),
                         (.center, "text.aligncenter", "Align center"),
                         (.trailing, "text.alignright", "Align right")],
                        id: \.0.hashValue
                    ) { alignment, icon, label in
                        Button {
                            canvas.updateAlignment(id: overlay.id, alignment: alignment)
                            haptics.selectionChanged()
                        } label: {
                            Image(systemName: icon)
                                .font(.body)
                                .foregroundStyle(
                                    overlay.alignment == alignment
                                        ? DS.Color.accent
                                        : DS.Color.textSecondary
                                )
                                .frame(width: 44, height: 44)
                                .background(
                                    overlay.alignment == alignment
                                        ? DS.Color.accent.opacity(0.15)
                                        : SwiftUI.Color.clear,
                                    in: RoundedRectangle(cornerRadius: DS.Radius.sm)
                                )
                        }
                        .accessibilityLabel(label)
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
                        ),
                        recentColorHexes: settings.recentColors,
                        onColorUsed: { settings.addRecentColor(hex: $0) }
                    )
                    ContrastBadge(
                        foreground: overlay.textColor,
                        background: DS.Color.canvas
                    )
                }

                // MARK: - Presets button
                Button { showPresets = true } label: {
                    Text("PRESETS")
                        .font(DS.Typography.label)
                        .tracking(1.5)
                        .foregroundStyle(DS.Color.accent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DS.Spacing.md)
                        .background(DS.Color.accentSubtle, in: RoundedRectangle(cornerRadius: DS.Radius.md))
                }
                .accessibilityLabel("Open style presets")
                .sheet(isPresented: $showPresets) {
                    PresetSheetView()
                        .environment(canvas)
                        .environment(presetStore)
                        .presentationDetents([.medium, .large])
                        .presentationDragIndicator(.visible)
                        .presentationBackground(DS.Color.surface)
                }
            }
            .padding(DS.Spacing.xl)
        }
    }
}

// MARK: - ContrastBadge

/// Inline WCAG 2.1 AA indicator shown below the colour picker.
/// A green dot + ratio means the current text colour is accessible
/// on the default canvas background; a red dot flags a failure.
private struct ContrastBadge: View {
    private typealias DS = GlyphDesignSystem
    let foreground: Color
    let background: Color

    private var ratio: Double { ContrastService.ratio(foreground: foreground, background: background) }
    private var passes: Bool  { ContrastService.passesAA(foreground: foreground, background: background) }

    var body: some View {
        HStack(spacing: DS.Spacing.xs) {
            Circle()
                .fill(passes ? DS.Color.success : DS.Color.error)
                .frame(width: 8, height: 8)
            Text(String(format: "%.1f:1 %@", ratio, passes ? "AA" : "FAIL"))
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(DS.Color.textSecondary)
        }
    }
}
