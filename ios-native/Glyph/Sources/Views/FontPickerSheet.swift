import SwiftUI
import UniformTypeIdentifiers

private typealias DS = GlyphDesignSystem

/// Bottom sheet for browsing and importing fonts.
struct FontPickerSheet: View {
    @Environment(CanvasViewModel.self) private var canvas
    @Environment(FontLibraryViewModel.self) private var fontLibrary
    @Environment(\.dismiss) private var dismiss

    @State private var showImporter = false
    @State private var importError = false

    var body: some View {
        NavigationStack {
            List {
                Section("Built-in") {
                    ForEach(fontLibrary.bundledFonts) { entry in
                        fontRow(entry)
                    }
                }

                if !fontLibrary.customFonts.isEmpty {
                    Section("Your Fonts") {
                        ForEach(fontLibrary.customFonts) { entry in
                            fontRow(entry)
                        }
                        .onDelete { indexSet in
                            let customs = fontLibrary.customFonts
                            for index in indexSet {
                                fontLibrary.removeFont(id: customs[index].id)
                            }
                        }
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
                        Text("IMPORT")
                            .font(DS.Typography.label)
                            .tracking(1.5)
                            .foregroundStyle(DS.Color.accent)
                    }
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
            UISelectionFeedbackGenerator().selectionChanged()
            dismiss()
        } label: {
            HStack {
                Text(canvas.selectedTextLayer?.text.isEmpty == false
                     ? canvas.selectedTextLayer!.text
                     : entry.displayName)
                    .font(.custom(entry.familyName, size: 20))
                    .foregroundStyle(DS.Color.textPrimary)
                    .lineLimit(1)

                Spacer()

                if canvas.selectedTextLayer?.fontFamily == entry.familyName {
                    Image(systemName: "checkmark")
                        .foregroundStyle(DS.Color.accent)
                }
            }
            .padding(.vertical, DS.Spacing.xs)
        }
        .listRowBackground(DS.Color.canvas)
    }
}
