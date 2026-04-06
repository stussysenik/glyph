# Glyph

Custom font stickers for Instagram Stories. Type text, pick a font, style it, export a transparent PNG sticker.

Instagram doesn't support custom fonts — Glyph renders text locally and shares the finished image as a movable sticker.

## How It Works

1. Type text on the canvas
2. Pick a font — 5 bundled display fonts or import your own TTF/OTF
3. Style it — size, color, letter spacing, alignment
4. Add image layers, adjust backgrounds
5. Drag, pinch, rotate to position
6. Export as transparent PNG to Instagram Stories, Photos, or clipboard

Total time from open to Instagram: under 30 seconds.

## Screenshots

> TODO: Add screenshots after TestFlight build

## Architecture

### Native SwiftUI (Primary — `ios-native/Glyph/`)

The primary app. Pure SwiftUI with UIKit for rendering and export.

- **Target:** iOS 17+, Swift 6
- **Pattern:** `@Observable` MVVM
- **Font loading:** `CTFontManager` for runtime TTF/OTF registration
- **Canvas:** Multi-layer system — text overlays, image overlays, background images
- **Gestures:** Drag, pinch-to-resize, rotation with snap-to-angle
- **Alignment:** Smart snap guides (center, thirds, edges) with haptic feedback
- **Export:** `UIGraphicsImageRenderer` compositing layers in z-order to transparent PNG
- **Share:** Instagram Stories via `UIPasteboard` + `instagram-stories://` URL scheme
- **Tests:** 109 unit tests across 8 suites, 2 Maestro E2E flows

### Flutter (Secondary — `flutter/`)

Cross-platform version for eventual Android support. Flutter + Riverpod.

## Project Structure

```
glyph/
├── ios-native/Glyph/
│   ├── Sources/
│   │   ├── GlyphApp.swift                  # App entry point
│   │   ├── GlyphDesignSystem.swift         # Design tokens
│   │   ├── Models/                         # Data: CanvasLayer, FontEntry, Guide, StylePreset
│   │   ├── ViewModels/                     # State: CanvasViewModel, FontLibraryViewModel, SettingsViewModel
│   │   ├── Views/                          # UI: CanvasView, TextOverlayView, ExportSheet, FontPickerSheet, ...
│   │   ├── Services/                       # Logic: FontLoader, ExportEngine, InstagramSharer, HapticsService
│   │   ├── Engine/                         # AlignmentEngine (snap computation)
│   │   └── Store/                          # PresetStore (JSON persistence)
│   ├── Tests/GlyphTests/                   # 8 test suites, 109 tests
│   ├── Resources/                          # Assets, fonts, Info.plist
│   └── project.yml                         # XcodeGen configuration
│
├── flutter/                                # Flutter cross-platform version
├── maestro/                                # E2E test flows
├── openspec/                               # Spec change proposals
├── tasks/                                  # Build progress & lessons learned
└── SPEC.md                                 # Full product specification
```

## Getting Started

### Prerequisites

- Xcode 16+ with iOS 17 SDK
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (for regenerating `.xcodeproj`)
- [FlowDeck](https://flowdeck.studio) (recommended) or `xcodebuild`

### Build & Run

```bash
cd ios-native/Glyph

# Generate Xcode project (if project.yml changed)
xcodegen generate

# Build
flowdeck build -w Glyph.xcodeproj -s Glyph -S "iPhone 17 Pro"

# Run on simulator
flowdeck run -w Glyph.xcodeproj -s Glyph -S "iPhone 17 Pro"

# Run tests (109 unit tests)
flowdeck test -w Glyph.xcodeproj -s Glyph -S "iPhone 17 Pro"
```

Or open `Glyph.xcodeproj` in Xcode and build normally.

### Flutter (secondary)

```bash
cd flutter
flutter pub get
flutter run
```

## Features

### Canvas & Layers
- Multi-layer canvas with z-ordering, lock, and visibility toggles
- Text overlays with full gesture support (drag, pinch, rotate)
- Image overlays from photo library
- Background images with pinch-to-zoom and pan (clamped to canvas)
- Layer panel with drag-to-reorder

### Typography
- 5 bundled OFL fonts: Playfair Display, Space Grotesk, Archivo Black, Caveat, DM Serif Display
- Import custom TTF/OTF fonts at runtime
- Style controls: font size, color, letter spacing, alignment
- Live font preview in picker using your actual text

### Smart Alignment
- Snap guides: center lines, rule-of-thirds, edge alignment
- Configurable snap threshold
- 8x14 grid overlay with rule-of-thirds option
- Haptic feedback on snap events

### Export
- Transparent PNG export at 1080x1920 (story resolution)
- JPEG option with configurable quality
- Share to Instagram Stories as movable sticker
- Save to Photos
- Copy to clipboard

### Style Presets
- Save and load text style combinations
- JSON persistence in Documents directory
- Rename, delete, reorder presets

### Accessibility
- VoiceOver labels on all 19+ interactive elements
- Keyboard arrow-key nudge for selected layers
- WCAG 2.1 contrast ratio calculator with AA badge
- Haptic feedback: snap, lock, delete, export, selection

### Settings
- Grid default on/off
- Snap threshold adjustment
- Export format (PNG/JPEG) and quality
- Accent color picker (8 presets)

## Testing

### Unit Tests (109 passing)

| Suite | Coverage |
|-------|----------|
| AlignmentEngineTests | Snap computation, edge cases, thresholds |
| ExportEngineTests | PNG rendering, layer compositing |
| LayerOrderTests | Z-ordering, move, lock, visibility |
| PresetCodableTests | Codable round-trip, color encoding |
| SnapIntegrationTests | Full integration with CanvasViewModel |
| RotationSnapEngineTests | Angle snapping at 0/45/90/180/270 |
| UndoStackTests | Push, undo, redo, capacity |
| CustomGuideTests | User-defined guide creation |

### E2E Tests (Maestro)

```bash
maestro test maestro/flow1_add_text_export.yaml
maestro test maestro/flow2_layer_management.yaml
```

## Bundled Fonts

All fonts are [SIL Open Font License](https://scripts.sil.org/cms/scripts/page.php?item_id=OFL_web) — free for any use:

| Font | Style | Use Case |
|------|-------|----------|
| Playfair Display | Elegant serif | Headlines, quotes |
| Space Grotesk | Modern geometric sans | Clean, tech |
| Archivo Black | Bold condensed | Impact, titles |
| Caveat | Handwritten | Casual, personal |
| DM Serif Display | Classic serif | Editorial, branding |

## Roadmap

See [tasks/todo.md](tasks/todo.md) for current progress. Key next steps:

- [ ] Physical device testing with Instagram installed
- [ ] Transparent PNG alpha verification end-to-end
- [ ] TestFlight beta build
- [ ] Performance: cached sortedLayers, reduced allocations
- [ ] Text effects: stroke, shadow, gradient (v1.5)
- [ ] Android support via Flutter (v1.5)

## License

MIT
