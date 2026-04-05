import SwiftUI
import UniformTypeIdentifiers

/// Manages the font library: bundled fonts + user-imported fonts with persistence.
@Observable
final class FontLibraryViewModel {
    var fonts: [FontEntry] = []
    var isShowingImporter = false

    private let storageKey = "glyph_custom_fonts"

    init() {
        fonts = FontEntry.bundled + loadCustomFonts()
        registerCustomFonts()
    }

    /// All bundled fonts.
    var bundledFonts: [FontEntry] {
        fonts.filter { $0.isBundled }
    }

    /// All user-imported fonts.
    var customFonts: [FontEntry] {
        fonts.filter { !$0.isBundled }
    }

    // MARK: - Import

    /// Handle a picked font file URL. Copies to app documents, registers, and persists.
    func importFont(from url: URL) -> Bool {
        guard url.startAccessingSecurityScopedResource() else { return false }
        defer { url.stopAccessingSecurityScopedResource() }

        // Validate
        guard FontLoader.validate(url: url) else { return false }

        // Copy to app documents
        let documentsDir = fontsDirectory()
        let filename = "\(Int(Date().timeIntervalSince1970))_\(url.lastPathComponent)"
        let destURL = documentsDir.appendingPathComponent(filename)

        do {
            try FileManager.default.copyItem(at: url, to: destURL)
        } catch {
            print("[FontLibrary] Copy failed: \(error)")
            return false
        }

        // Register with CoreText
        guard let familyName = FontLoader.register(url: destURL) else {
            try? FileManager.default.removeItem(at: destURL)
            return false
        }

        let displayName = url.deletingPathExtension().lastPathComponent
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "_", with: " ")

        let entry = FontEntry(
            displayName: displayName,
            familyName: familyName,
            filePath: destURL.path,
            isBundled: false
        )

        fonts.append(entry)
        saveCustomFonts()
        return true
    }

    /// Remove a custom font.
    func removeFont(id: UUID) {
        guard let entry = fonts.first(where: { $0.id == id }),
              !entry.isBundled else { return }

        // Delete file
        if let path = entry.filePath {
            try? FileManager.default.removeItem(atPath: path)
        }

        fonts.removeAll { $0.id == id }
        saveCustomFonts()
    }

    // MARK: - Persistence

    private func saveCustomFonts() {
        let custom = fonts.filter { !$0.isBundled }
        if let data = try? JSONEncoder().encode(custom) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func loadCustomFonts() -> [FontEntry] {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let entries = try? JSONDecoder().decode([FontEntry].self, from: data) else {
            return []
        }
        return entries
    }

    private func registerCustomFonts() {
        for entry in fonts where !entry.isBundled {
            guard let path = entry.filePath else { continue }
            let url = URL(fileURLWithPath: path)
            if FileManager.default.fileExists(atPath: path) {
                _ = FontLoader.register(url: url)
            }
        }
    }

    private func fontsDirectory() -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fontsDir = docs.appendingPathComponent("fonts")
        try? FileManager.default.createDirectory(at: fontsDir, withIntermediateDirectories: true)
        return fontsDir
    }
}
