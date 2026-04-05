import SwiftUI

private typealias DS = GlyphDesignSystem

// MARK: - PresetSheetView

/// Bottom sheet displaying all style presets with save, apply, rename,
/// and swipe-to-delete actions.
struct PresetSheetView: View {
    @Environment(PresetStore.self) private var store
    @Environment(CanvasViewModel.self) private var vm

    @State private var newPresetName: String = ""
    @State private var isSaveFieldVisible: Bool = false
    @State private var renameTarget: StylePreset? = nil
    @State private var renameText: String = ""

    var body: some View {
        NavigationStack {
            List {
                // MARK: Save current style section
                if let layer = vm.selectedTextLayer {
                    Section {
                        if isSaveFieldVisible {
                            HStack {
                                TextField("Preset name", text: $newPresetName)
                                    .font(DS.Typography.body)
                                Button("Save") {
                                    let trimmed = newPresetName.trimmingCharacters(in: .whitespaces)
                                    guard !trimmed.isEmpty else { return }
                                    store.saveFromLayer(layer, name: trimmed)
                                    newPresetName = ""
                                    isSaveFieldVisible = false
                                }
                                .foregroundStyle(DS.Color.accent)
                            }
                        } else {
                            Button {
                                isSaveFieldVisible = true
                            } label: {
                                Label("Save Current Style…", systemImage: "plus.circle")
                                    .foregroundStyle(DS.Color.accent)
                            }
                        }
                    } header: {
                        Text("SAVE CURRENT STYLE")
                            .font(DS.Typography.label)
                            .tracking(1.5)
                    }
                }

                // MARK: Preset list section
                Section {
                    ForEach(store.presets) { preset in
                        presetRow(preset)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                if !preset.isBuiltIn {
                                    Button(role: .destructive) {
                                        store.delete(preset: preset)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }

                                    Button {
                                        renameTarget = preset
                                        renameText = preset.name
                                    } label: {
                                        Label("Rename", systemImage: "pencil")
                                    }
                                    .tint(DS.Color.accent)
                                }
                            }
                    }
                } header: {
                    Text("PRESETS")
                        .font(DS.Typography.label)
                        .tracking(1.5)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Style Presets")
            .navigationBarTitleDisplayMode(.inline)
        }
        // Rename alert driven by optional renameTarget
        .alert("Rename Preset", isPresented: Binding(
            get: { renameTarget != nil },
            set: { if !$0 { renameTarget = nil } }
        )) {
            TextField("New name", text: $renameText)
            Button("Rename") {
                if let target = renameTarget {
                    store.rename(preset: target, to: renameText)
                }
                renameTarget = nil
            }
            Button("Cancel", role: .cancel) { renameTarget = nil }
        }
    }

    // MARK: - Row

    private func presetRow(_ preset: StylePreset) -> some View {
        Button {
            guard let id = vm.selectedLayerID else { return }
            preset.apply(to: vm, layerID: id)
        } label: {
            HStack(spacing: DS.Spacing.md) {
                // Thumbnail: "Aa" rendered in the preset's font + color
                Text("Aa")
                    .font(.custom(preset.fontFamily, size: 20))
                    .foregroundStyle(preset.textColor.swiftUIColor)
                    .tracking(preset.letterSpacing)
                    .frame(width: 56, height: 44)
                    .background(DS.Color.surfaceAlt, in: RoundedRectangle(cornerRadius: DS.Radius.sm))

                VStack(alignment: .leading, spacing: 2) {
                    Text(preset.name)
                        .font(DS.Typography.body)
                        .foregroundStyle(DS.Color.textPrimary)
                    Text("\(preset.fontFamily) · \(Int(preset.fontSize))pt")
                        .font(DS.Typography.caption)
                        .foregroundStyle(DS.Color.textSecondary)
                }

                Spacer()

                if preset.isBuiltIn {
                    Image(systemName: "star.fill")
                        .font(DS.Typography.caption)
                        .foregroundStyle(DS.Color.textTertiary)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
