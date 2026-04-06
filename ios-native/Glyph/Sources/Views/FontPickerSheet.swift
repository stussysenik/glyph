import SwiftUI
import UniformTypeIdentifiers

private typealias DS = GlyphDesignSystem

/// Bottom sheet for browsing and importing fonts.
struct FontPickerSheet: View {
    @Environment(CanvasViewModel.self) private var canvas
    @Environment(FontLibraryViewModel.self) private var fontLibrary
    @Environment(HapticsService.self) private var haptics
    @Environment(\.dismiss) private var dismiss

    @State private var showImporter = false
    @State private var importError = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(fontLibrary.bundledFonts) { entry in
                        fontRow(entry)
                    }
                } header: {
                    Label("Built-in", systemImage: "textformat")
                }

                if !fontLibrary.customFonts.isEmpty {
                    Section {
                        ForEach(fontLibrary.customFonts) { entry in
                            fontRow(entry)
                        }
                        .onDelete { indexSet in
                            let customs = fontLibrary.customFonts
                            for index in indexSet {
                                fontLibrary.removeFont(id: customs[index].id)
                            }
                        }
                    } header: {
                        Label("Your Fonts", systemImage: "folder")
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(DS.Color.surface)
            .navigationTitle("Fonts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showImporter = true
                    } label: {
                        HStack(spacing: DS.Spacing.xs) {
                            Image(systemName: "plus.circle")
                                .font(.body)
                            Text("IMPORT")
                                .font(DS.Typography.label)
                                .tracking(1.5)
                        }
                        .foregroundStyle(DS.Color.accent)
                    }
                    .accessibilityLabel("Import custom font")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Text("DONE")
                            .font(DS.Typography.label)
                            .tracking(1.5)
                            .foregroundStyle(DS.Color.accent)
                    }
                }
            }
            .fileImporter(
                isPresented: $showImporter,
                allowedContentTypes: [
                    UTType(filenameExtension: "ttf") ?? .data,
                    UTType(filenameExtension: "otf") ?? .data,
                ],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        let success = fontLibrary.importFont(from: url)
                        if success, let last = fontLibrary.fonts.last,
                           let id = canvas.selectedLayerID {
                            canvas.updateFont(id: id, fontFamily: last.familyName)
                        } else if !success {
                            importError = true
                        }
                    }
                case .failure:
                    importError = true
                }
            }
            .alert("Import Failed", isPresented: $importError) {
                Button("OK") {}
            } message: {
                Text("Couldn't load this font file. Make sure it's a valid .ttf or .otf.")
            }
        }
    }

    @ViewBuilder
    private func fontRow(_ entry: FontEntry) -> some View {
        Button {
            if let id = canvas.selectedLayerID {
                canvas.updateFont(id: id, fontFamily: entry.familyName)
            }
            haptics.selectionChanged()
            dismiss()
        } label: {
            HStack(spacing: DS.Spacing.md) {
                // Font name rendered in its own typeface
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.displayName)
                        .font(.custom(entry.familyName, size: 20))
                        .foregroundStyle(DS.Color.textPrimary)
                        .lineLimit(1)

                    // Show a preview phrase in the font
                    let previewText = canvas.selectedTextLayer?.text ?? ""
                    if !previewText.isEmpty && previewText != "Tap to edit" {
                        Text(previewText)
                            .font(.custom(entry.familyName, size: 14))
                            .foregroundStyle(DS.Color.textSecondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                if canvas.selectedTextLayer?.fontFamily == entry.familyName {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(DS.Color.accent)
                        .font(.title3)
                }
            }
            .padding(.vertical, DS.Spacing.xs)
        }
        .listRowBackground(
            canvas.selectedTextLayer?.fontFamily == entry.familyName
                ? DS.Color.accent.opacity(0.08)
                : DS.Color.canvas
        )
    }
}
