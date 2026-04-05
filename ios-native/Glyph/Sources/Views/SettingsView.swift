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

    // MARK: - Canvas section

    private var canvasSection: some View {
        Section("Canvas") {
            @Bindable var s = settings
            Toggle("Show Grid by Default", isOn: $s.showGridByDefault)
                .tint(DS.Color.accent)
            VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                Text("Snap Threshold: \(Int(settings.snapThreshold)) pt")
                    .font(DS.Typography.body)
                Slider(value: $s.snapThreshold, in: 2...24, step: 1)
                    .tint(DS.Color.accent)
            }
        }
    }

    // MARK: - Export section

    private var exportSection: some View {
        Section("Export") {
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
