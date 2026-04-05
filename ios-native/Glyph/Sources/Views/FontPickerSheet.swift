import SwiftUI
import UniformTypeIdentifiers

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
                // Built-in section
                Section("Built-in") {
                    ForEach(fontLibrary.bundledFonts) { entry in
                        fontRow(entry)
                    }
                }

                // Custom fonts section
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
            .background(GlyphTheme.surface)
            .navigationTitle("Fonts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Import") {
                        showImporter = true
                    }
                    .foregroundStyle(GlyphTheme.accent)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(GlyphTheme.accent)
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
                        if success, let last = fontLibrary.fonts.last {
                            canvas.updateFont(last.familyName)
                        } else {
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
            canvas.updateFont(entry.familyName)
            UISelectionFeedbackGenerator().selectionChanged()
            dismiss()
        } label: {
            HStack {
                Text(canvas.selectedOverlay?.text.isEmpty == false
                     ? canvas.selectedOverlay!.text
                     : entry.displayName)
                    .font(.custom(entry.familyName, size: 20))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Spacer()

                if canvas.selectedOverlay?.fontFamily == entry.familyName {
                    Image(systemName: "checkmark")
                        .foregroundStyle(GlyphTheme.accent)
                }
            }
            .padding(.vertical, 4)
        }
        .listRowBackground(GlyphTheme.surfaceLight)
    }
}
