# Glyph — Build Progress

## Completed
- [x] Product spec (SPEC.md) — Pattern A, iPhone-first, Flutter
- [x] Architecture plan — font engine, canvas, export pipeline, Instagram share
- [x] Validation checklist — 15 truth gates defined
- [x] Flutter project scaffold — dependencies, directory structure
- [x] Font loading engine — FontManager, FontEntry, FontListNotifier, file picker
- [x] Text rendering canvas — CanvasScreen, live preview, Google Fonts bundled
- [x] Style controls — font size, color, letter spacing, alignment
- [x] Export pipeline — PNG capture, gallery save, Instagram share, clipboard
- [x] iOS platform channel — InstagramSharePlugin with pasteboard + URL scheme
- [x] Font picker sheet — bottom sheet, section headers, live preview per font
- [x] Export sheet — Instagram Stories, Save to Photos, Copy Image
- [x] iOS build verification — compiles clean, zero analyzer issues
- [x] Widget test — app launches correctly
- [x] Design system — GlyphDesignSystem tokens (colors, typography, spacing, radius, shadows)
- [x] ComponentCatalog — SwiftUI preview Storybook for all tokens
- [x] Layer system — Layer protocol, TextLayer, ImageLayer, CanvasBackground
- [x] CanvasViewModel migration — overlay-based → layer-based with z-order, lock, visibility, multi-select
- [x] Image import — PHPickerViewController wrapper (ImagePickerView)
- [x] Background image — BackgroundImageView with pinch-to-zoom, pan
- [x] Image overlays — ImageOverlayView with drag, resize, rotate
- [x] TextOverlayView — Migrated to callback-based Layer API
- [x] Layer panel — LayerPanelView with drag-to-reorder, lock, visibility toggles
- [x] CanvasView rewrite — Full layer system integration (BG, images, text, layers sheet)
- [x] ExportEngine — Composites background → image layers → text layers in z-order
- [x] Alignment engine — Pure snap computation (AlignmentEngine + LayerGeometry)
- [x] Guide types — GuideAxis, GuideKind, Guide value types
- [x] Grid overlay — GuidesOverlayView (8×14 grid, rule-of-thirds, snap lines)
- [x] Guide state — showGuides, activeGuides, axisConstrained in CanvasViewModel
- [x] Style presets — StylePreset model, CodableColor, CodableAlignment
- [x] Preset store — PresetStore with JSON persistence in Documents
- [x] Preset sheet — PresetSheetView with save, apply, rename, delete
- [x] HapticsService — Centralized haptics (snap, lock, delete, export, selection)
- [x] ContrastService — WCAG 2.1 ratio calculator + AA badge in StyleControls
- [x] SettingsViewModel — @AppStorage persistence (grid default, snap threshold, export format)
- [x] SettingsView — Form with Canvas, Export, About sections
- [x] Keyboard shortcuts — Arrow-key nudge for selected layer
- [x] **Live snap alignment** — AlignmentEngine wired into updatePosition() with haptic feedback
- [x] **Export format/quality** — JPEG support via renderToData(), settings-driven clipboard export
- [x] **Accessibility** — 19 labels across 6 view files, all interactive elements labeled
- [x] **Code cleanup** — Deleted orphaned TextOverlay, fixed force-unwrap, centralized haptics
- [x] Unit tests — 36 tests in 5 suites (AlignmentEngine, ExportEngine, LayerOrder, PresetCodable, SnapIntegration)
- [x] Maestro flows — E2E test flows for add text + layer management

## Next Steps (Priority Order)
- [ ] Register Facebook App ID at developers.facebook.com
- [ ] Test on physical iOS device with Instagram installed (critical spike)
- [ ] Verify transparent PNG alpha preservation end-to-end
- [ ] Test with 10+ real TTF/OTF files for font loading reliability
- [ ] Progressive onboarding hints (3 hints)
- [ ] Error state handling for permissions
- [ ] TestFlight beta build

## Deferred (v1.5+)
- [ ] Text effects: stroke, shadow, gradient
- [ ] Multi-line with line height control
- [ ] Background color/gradient export
- [ ] Video export (animated text reveal)
- [ ] Android platform support
- [ ] Phosphor icons (replace SF Symbols)
