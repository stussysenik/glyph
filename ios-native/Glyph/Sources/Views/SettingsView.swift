import SwiftUI

/// App-wide settings sheet.
///
/// Present this modally from `CanvasView` via the gear button in the
/// top toolbar. All preferences are persisted automatically through
/// `SettingsViewModel`'s `@AppStorage` backing.
struct SettingsView: View {
    private typealias DS = GlyphDesignSystem

    @Environment(SettingsViewModel.self) private var settings
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                accentColorSection
                canvasSection
                exportSection
                aboutSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(DS.Color.accent)
                }
            }
        }
    }

    // MARK: - Accent Color

    private var accentColorSection: some View {
        Section {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 12) {
                ForEach(SettingsViewModel.accentPresets, id: \.hex) { preset in
                    let isSelected = (settings.accentColorHex == 0 && preset.hex == GlyphDesignSystem.defaultAccentHex)
                        || UInt(settings.accentColorHex) == preset.hex
                    Button {
                        settings.accentColorHex = preset.hex == GlyphDesignSystem.defaultAccentHex ? 0 : Int(preset.hex)
                    } label: {
                        Circle()
                            .fill(Color(hex: preset.hex))
                            .frame(width: 36, height: 36)
                            .overlay {
                                if isSelected {
                                    Circle().stroke(DS.Color.textPrimary, lineWidth: 2.5)
                                        .padding(-3)
                                }
                            }
                    }
                    .frame(width: 44, height: 44)
                    .contentShape(Circle())
                    .accessibilityLabel(preset.name)
                    .accessibilityAddTraits(isSelected ? [.isSelected] : [])
                }
            }
            .padding(.vertical, DS.Spacing.xs)
        } header: {
            Label("Accent Color", systemImage: "paintpalette")
        }
    }

    // MARK: - Canvas section

    private var canvasSection: some View {
        Section {
            @Bindable var s = settings
            Toggle("Show Grid by Default", isOn: $s.showGridByDefault)
                .tint(DS.Color.accent)

            Picker("Grid Style", selection: $s.gridTypeRaw) {
                ForEach(GridType.allCases) { type in
                    Text(type.label).tag(type.rawValue)
                }
            }

            if settings.gridType == .even {
                VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                    Text("Grid Columns: \(settings.gridColumns)")
                        .font(DS.Typography.body)
                    Slider(value: .init(
                        get: { Double(settings.gridColumns) },
                        set: { settings.gridColumns = Int($0) }
                    ), in: 2...16, step: 1)
                        .tint(DS.Color.accent)
                }
            }

            Toggle("Center Crosshair", isOn: $s.showCenterGuides)
                .tint(DS.Color.accent)

            VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                Text("Snap Threshold: \(Int(settings.snapThreshold)) pt")
                    .font(DS.Typography.body)
                Slider(value: $s.snapThreshold, in: 2...24, step: 1)
                    .tint(DS.Color.accent)
                Text("tighter ←  → more magnetic")
                    .font(DS.Typography.caption)
                    .foregroundStyle(DS.Color.textTertiary)
            }
        } header: {
            Label("Canvas", systemImage: "square.grid.3x3")
        }
    }

    // MARK: - Export section

    private var exportSection: some View {
        Section {
            @Bindable var s = settings
            Picker("Format", selection: $s.exportFormat) {
                Text("PNG").tag("png")
                Text("JPEG").tag("jpeg")
            }
            .pickerStyle(.segmented)

            if !settings.exportFormatIsPNG {
                VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                    Text("JPEG Quality: \(Int(settings.exportQuality * 100))%")
                        .font(DS.Typography.body)
                    Slider(value: $s.exportQuality, in: 0.5...1.0, step: 0.05)
                        .tint(DS.Color.accent)
                }
            }
        } header: {
            Label("Export", systemImage: "square.and.arrow.up")
        }
    }

    // MARK: - About section

    private var aboutSection: some View {
        Section("About") {
            LabeledContent("Version") {
                Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                    .foregroundStyle(DS.Color.textSecondary)
            }
        }
    }
}
