import SwiftUI

@main
struct GlyphApp: App {
    @State private var canvasVM = CanvasViewModel()
    @State private var fontLibraryVM = FontLibraryViewModel()
    @State private var presetStore = PresetStore()
    @State private var haptics = HapticsService()
    @State private var settings = SettingsViewModel()

    var body: some Scene {
        WindowGroup {
            CanvasView()
                .environment(canvasVM)
                .environment(fontLibraryVM)
                .environment(presetStore)
                .environment(haptics)
                .environment(settings)
        }
    }
}
