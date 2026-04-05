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

## Next Steps (Priority Order)
- [ ] Register Facebook App ID at developers.facebook.com
- [ ] Test on physical iOS device with Instagram installed (critical spike)
- [ ] Verify transparent PNG alpha preservation end-to-end
- [ ] Test with 10+ real TTF/OTF files for font loading reliability
- [ ] Add haptic feedback polish pass
- [ ] Progressive onboarding hints (3 hints)
- [ ] Error state handling for permissions
- [ ] TestFlight beta build

## Deferred (v1.5+)
- [ ] Text effects: stroke, shadow, gradient
- [ ] Multi-line with line height control
- [ ] Style presets / favorites
- [ ] Background color/gradient export
- [ ] Video export (animated text reveal)
- [ ] Android platform support
