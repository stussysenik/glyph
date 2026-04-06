import SwiftUI

/// Grid overlay style.
enum GridType: String, CaseIterable, Identifiable {
    case even = "even"
    case ruleOfThirds = "thirds"
    case goldenRatio = "golden"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .even: "Grid"
        case .ruleOfThirds: "Rule of Thirds"
        case .goldenRatio: "Golden Ratio"
        }
    }
}

/// Persisted user preferences surfaced through `SettingsView`.
///
/// Properties are tracked by `@Observable` so SwiftUI knows exactly
/// which views to re-render when a specific setting changes.
/// Persistence is handled via manual UserDefaults read/write in
/// `init()` and `didSet`, replacing the broken `@ObservationIgnored
/// @AppStorage` pattern that prevented observation tracking entirely.
@Observable
final class SettingsViewModel {

    // MARK: - Canvas preferences

    var showGridByDefault: Bool = false {
        didSet { defaults.set(showGridByDefault, forKey: Keys.showGridByDefault) }
    }

    var snapThreshold: Double = 8.0 {
        didSet { defaults.set(snapThreshold, forKey: Keys.snapThreshold) }
    }

    var gridTypeRaw: String = GridType.even.rawValue {
        didSet { defaults.set(gridTypeRaw, forKey: Keys.gridType) }
    }

    var gridColumns: Int = 8 {
        didSet { defaults.set(gridColumns, forKey: Keys.gridColumns) }
    }

    var showCenterGuides: Bool = true {
        didSet { defaults.set(showCenterGuides, forKey: Keys.showCenterGuides) }
    }

    // MARK: - Appearance

    var accentColorHex: Int = 0 {
        didSet { defaults.set(accentColorHex, forKey: Keys.accentColorHex) }
    }

    static let accentPresets: [(name: String, hex: UInt)] = [
        ("Neon Green",  0x39FF14),
        ("Electric Blue", 0x007AFF),
        ("Hot Pink",    0xFF2D55),
        ("Amber",       0xFF9500),
        ("Violet",      0xAF52DE),
        ("Teal",        0x5AC8FA),
        ("Red",         0xFF3B30),
        ("Mint",        0x00C7BE),
    ]

    // MARK: - Export preferences

    var exportQuality: Double = 1.0 {
        didSet { defaults.set(exportQuality, forKey: Keys.exportQuality) }
    }

    var exportFormat: String = "png" {
        didSet { defaults.set(exportFormat, forKey: Keys.exportFormat) }
    }

    // MARK: - Recent Colors

    var recentColors: [String] = [] {
        didSet { defaults.set(recentColors, forKey: Keys.recentColors) }
    }

    /// Add a hex color to the recent list (deduped, max 8).
    func addRecentColor(hex: String) {
        var updated = recentColors.filter { $0.lowercased() != hex.lowercased() }
        updated.insert(hex, at: 0)
        recentColors = Array(updated.prefix(8))
    }

    // MARK: - Computed helpers

    var gridType: GridType {
        get { GridType(rawValue: gridTypeRaw) ?? .even }
        set { gridTypeRaw = newValue.rawValue }
    }

    var exportFormatIsPNG: Bool { exportFormat == "png" }

    // MARK: - Persistence

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let showGridByDefault = "canvas.showGridByDefault"
        static let snapThreshold     = "canvas.snapThreshold"
        static let gridType          = "canvas.gridType"
        static let gridColumns       = "canvas.gridColumns"
        static let showCenterGuides  = "canvas.showCenterGuides"
        static let accentColorHex    = "app.accentColorHex"
        static let exportQuality     = "export.quality"
        static let exportFormat      = "export.format"
        static let recentColors      = "color.recentColors"
    }

    init() {
        let d = UserDefaults.standard
        // Only override defaults when a key exists (preserves declared defaults above).
        if d.object(forKey: Keys.showGridByDefault) != nil { showGridByDefault = d.bool(forKey: Keys.showGridByDefault) }
        if d.object(forKey: Keys.snapThreshold) != nil     { snapThreshold = d.double(forKey: Keys.snapThreshold) }
        if let raw = d.string(forKey: Keys.gridType)       { gridTypeRaw = raw }
        if d.object(forKey: Keys.gridColumns) != nil        { gridColumns = d.integer(forKey: Keys.gridColumns) }
        if d.object(forKey: Keys.showCenterGuides) != nil   { showCenterGuides = d.bool(forKey: Keys.showCenterGuides) }
        if d.object(forKey: Keys.accentColorHex) != nil     { accentColorHex = d.integer(forKey: Keys.accentColorHex) }
        if d.object(forKey: Keys.exportQuality) != nil      { exportQuality = d.double(forKey: Keys.exportQuality) }
        if let fmt = d.string(forKey: Keys.exportFormat)    { exportFormat = fmt }
        if let recents = d.stringArray(forKey: Keys.recentColors) { recentColors = recents }
    }
}
