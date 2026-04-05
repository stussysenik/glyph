import Foundation
import Observation

// MARK: - PresetStore

/// Observable JSON-backed store for StylePresets.
///
/// The in-memory `presets` array is always built-ins first, then user presets.
/// Only user presets are persisted to disk — built-ins are re-injected on every
/// load so the app can ship new built-ins without touching the JSON file.
@Observable
final class PresetStore {
    /// All presets: built-ins prepended, then user-saved presets.
    private(set) var presets: [StylePreset] = []

    private let fileName = "style-presets.json"

    private var fileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
    }

    init() { load() }

    // MARK: - Write

    /// Persists a single preset. If a preset with the same ID already exists
    /// in the user list it is updated in-place; otherwise it is appended.
    func save(preset: StylePreset) {
        var user = userPresets()
        if let idx = user.firstIndex(where: { $0.id == preset.id }) {
            user[idx] = preset
        } else {
            user.append(preset)
        }
        persist(user)
        reload()
    }

    /// Convenience: captures the current TextLayer state as a new user preset.
    func saveFromLayer(_ layer: TextLayer, name: String) {
        let preset = StylePreset.from(layer: layer, name: name)
        save(preset: preset)
    }

    /// Deletes a user preset. No-ops silently if called on a built-in.
    func delete(preset: StylePreset) {
        guard !preset.isBuiltIn else { return }
        var user = userPresets()
        user.removeAll { $0.id == preset.id }
        persist(user)
        reload()
    }

    /// Renames a user preset.
    func rename(preset: StylePreset, to newName: String) {
        var updated = preset
        updated.name = newName
        save(preset: updated)
    }

    // MARK: - Private helpers

    private func load() { reload() }

    private func reload() {
        presets = StylePreset.builtIns + userPresets()
    }

    /// Returns persisted user presets, filtering out any stale built-ins that
    /// were accidentally saved in older builds.
    private func userPresets() -> [StylePreset] {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([StylePreset].self, from: data)
        else { return [] }
        return decoded.filter { !$0.isBuiltIn }
    }

    private func persist(_ userPresets: [StylePreset]) {
        guard let data = try? JSONEncoder().encode(userPresets) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
