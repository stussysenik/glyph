import SwiftUI

@main
struct GlyphApp: App {
    @State private var canvasVM = CanvasViewModel()
    @State private var fontLibraryVM = FontLibraryViewModel()

    var body: some Scene {
        WindowGroup {
            CanvasView()
                .environment(canvasVM)
                .environment(fontLibraryVM)
                .preferredColorScheme(.dark)
        }
    }
}
