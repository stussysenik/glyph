# Glyph — Custom Font Stickers for Instagram Stories

Use your own fonts in Instagram Stories. Type text, pick a font, style it, export as a transparent PNG sticker.

Instagram doesn't support custom fonts — Glyph renders the text locally and shares the finished image.

## Repository Structure

```
glyph/
├── ios-native/Glyph/    # Native SwiftUI app (iOS 17+, primary)
├── flutter/              # Flutter cross-platform version
├── SPEC.md               # Product specification
└── tasks/                # Build progress & lessons
```

### Native SwiftUI (iOS)

The primary version. Pure SwiftUI + UIKit for rendering. 14 source files.

- `@Observable` MVVM architecture
- Multi-overlay canvas with drag/pinch/rotate gestures
- CTFontManager for runtime font loading (TTF/OTF)
- UIGraphicsImageRenderer for transparent PNG export
- Instagram Stories sharing via UIPasteboard + URL scheme
- 5 bundled OFL fonts

```bash
cd ios-native/Glyph
xcodegen generate          # Generate .xcodeproj
flowdeck build             # Or: xcodebuild build -scheme Glyph
```

### Flutter (Cross-platform)

For eventual Android support. Flutter + Riverpod, single-screen sticker maker.

```bash
cd flutter
flutter run
```

## How It Works

1. Type text on the canvas
2. Pick a font (bundled or import your own TTF/OTF)
3. Style it (size, color, spacing, alignment)
4. Drag, pinch, rotate to position
5. Export → transparent PNG → Instagram Stories sticker

No Facebook App ID needed for personal use.
