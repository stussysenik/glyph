# Lessons Learned

## Flutter iOS Scene Delegate
- Modern Flutter uses `FlutterImplicitEngineDelegate` with scene-based lifecycle
- `FlutterImplicitEngineBridge` does NOT expose `.engine` property directly
- Register platform channels via `FlutterPlugin` pattern using `registrar(forPlugin:)`
- The registrar may be optional — always unwrap with `if let`

## Dependencies
- `image_gallery_saver_plus` latest may not always be on pub.dev — check exact version
- `google_fonts` handles bundled font loading via network, good for v1 but consider bundling assets for offline

## iOS Config
- Must add `LSApplicationQueriesSchemes` with `instagram-stories` to Info.plist
- Must add `FacebookAppID` to Info.plist
- Photo library permissions need both `NSPhotoLibraryAddUsageDescription` and `NSPhotoLibraryUsageDescription`

## Font Bundling (Xcode)
- When fonts are added as individual files (Xcode group, not folder reference), they copy to the **bundle root** — NOT into a subdirectory
- Info.plist `UIAppFonts` paths must match: use `PlayfairDisplay-Bold.ttf` not `Fonts/PlayfairDisplay-Bold.ttf`
- Always verify font files with `file` command — a failed download can produce an HTML file with a `.ttf` extension
- PlayfairDisplay-Bold.ttf was an HTML file (Google Fonts 404) — re-downloaded from `fonts.googleapis.com/css2` CDN URL

## Performance — iOS Native
- `CTFontManagerRegisterFontsForURL` is I/O-bound and blocks main thread — register custom fonts via `Task.detached`
- Bundled fonts (Info.plist UIAppFonts) are registered by iOS before app code runs — no manual registration needed
- Export rendering is expensive (1080×1920 UIGraphicsImageRenderer) — cache the result, don't render per export action
- SwiftUI computed properties in `@Observable` are re-evaluated every view render — cache `sortedLayers` instead of sorting per frame
