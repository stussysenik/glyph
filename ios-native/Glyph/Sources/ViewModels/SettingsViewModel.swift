import SwiftUI

/// Persisted user preferences surfaced through `SettingsView`.
///
/// All values are stored in `UserDefaults` via `@AppStorage` so they
/// survive app restarts without any explicit save/load logic.
/// Inject this into the environment from `GlyphApp` so every view
/// that needs a preference can read it without prop-drilling.
@Observable
final class SettingsViewModel {

    // MARK: - Canvas preferences

    /// Show the alignment grid automatically when the canvas loads.
    @ObservationIgnored
    @AppStorage("canvas.showGridByDefault") var showGridByDefault: Bool = false

    /// Distance in points at which a dragged layer snaps to a guide.
    @ObservationIgnored
    @AppStorage("canvas.snapThreshold") var snapThreshold: Double = 8.0

    // MARK: - Export preferences

    /// JPEG quality multiplier (0.5 … 1.0). Ignored when format is PNG.
    @ObservationIgnored
    @AppStorage("export.quality") var exportQuality: Double = 1.0

    /// Raw format identifier — `"png"` or `"jpeg"`.
    @ObservationIgnored
    @AppStorage("export.format") var exportFormat: String = "png"

    // MARK: - Computed helpers

    /// Convenience flag used to conditionally hide JPEG-only controls.
    var exportFormatIsPNG: Bool { exportFormat == "png" }
}
