# Glyph — Instagram Story Font Sticker Maker

## Executive Recommendation

**Build Pattern A: Font Sticker Maker.** Ship iPhone-first with Flutter. The entire value prop is: *type text in your font, get a transparent sticker, drop it into Instagram Stories.* Everything else is v2.

**v1 in one sentence:** A single-screen app where you type text, pick your font, style it, and export a transparent PNG sticker directly into Instagram Stories.

**Go/No-Go:** If a custom TTF renders to transparent PNG and lands in Instagram Stories as a movable sticker within 2 weeks of development, the product is viable. If any of those three steps fail, stop.

---

## 1. /spec — Product Specification

### Product Statement

Glyph lets creators use their own custom fonts in Instagram Stories. You import a TTF/OTF, type your text, style it, and export a transparent PNG sticker that drops directly into the Instagram Stories composer. The font renders in our app — Instagram receives a finished image asset.

### User Value

Creators, brand owners, and designers want typographic identity in their Stories. Instagram's built-in fonts are generic and shared by billions of users. Custom typography is the single highest-signal visual differentiator in Stories. Glyph gives them that in under 30 seconds.

### Non-Negotiable Platform Constraints

| Constraint | Status | Source |
|---|---|---|
| Instagram does NOT allow third-party custom fonts in its native text editor | **Certain** | Platform limitation — no API exists |
| The only reliable path is rendering text ourselves and sharing as an image/video asset | **Certain** | Architectural constraint |
| Meta's Sharing to Stories API accepts background images, sticker images, and videos via iOS URL schemes and Android Intents | **Documented** | [Meta Developer Docs](https://developers.facebook.com/docs/instagram-platform/sharing-to-stories/) |
| A Facebook App ID is required for the Stories sharing flow | **Documented** | Meta Developer Docs |
| Story assets target 1080×1920 (9:16) with UI-safe zones (~250px top/bottom) | **Documented** | [Meta Ad Specs](https://www.facebook.com/business/help/292794301336717) |
| Sticker images support transparency (PNG with alpha) in the Stories composer | **Documented, needs prototype validation** | Meta docs + community reports |
| iOS uses `instagram-stories://share` URL scheme + UIPasteboard | **Documented** | Meta Developer Docs |
| Android uses `com.instagram.share.ADD_TO_STORY` Intent | **Documented** | Meta Developer Docs |

### What This Product Is NOT

- NOT a way to add editable custom fonts to Instagram's text tool (impossible)
- NOT a full story composer (v2+ territory)
- NOT a font creation/glyph drawing tool (v3+ territory)
- NOT a social platform or community
- NOT a font marketplace (licensing complexity)

---

## 2. /plan — Pattern Choice & Roadmap

### Pattern Choice: A — Font Sticker Maker

**Why Pattern A over B or C:**

| Dimension | Pattern A (Sticker Maker) | Pattern B (Story Composer) | Pattern C (Font Builder) |
|---|---|---|---|
| Time-to-value | **2-4 weeks** | 8-12 weeks | 16+ weeks |
| Technical risk | Low — PNG render + share | Medium — layers, video, templates | High — glyph editor, kerning, hinting |
| UX quality | Can be excellent in narrow scope | Spread thin across many features | Completely different product |
| Defensibility | Font library + workflow speed | Template library + brand kits | Custom font IP |
| Monetization | Pro fonts, unlimited exports | Templates, brand kits | Font sales, subscriptions |

**Rationale:** Pattern A is the only one that can ship in weeks, prove demand, and still feel magical. A sticker maker that exports transparent PNGs in your font is *complete enough* to be genuinely useful. Pattern B requires solving layout, layers, backgrounds, and video — all before you prove anyone cares about custom fonts in Stories. Pattern C is a completely different company.

### Staged Roadmap

#### v1 — Font Sticker Maker (Weeks 1-4)
- Import TTF/OTF from device files
- Type text with custom font preview
- Basic styling: size, color, alignment, letter spacing
- Transparent PNG export at story resolution
- Save to camera roll
- Share directly to Instagram Stories as sticker
- 3-5 bundled display fonts for zero-friction onboarding
- Font licensing notice on import

#### v1.5 — Polish & Retention (Weeks 5-8)
- Text effects: outline/stroke, drop shadow, gradient fill
- Recent fonts / favorites
- Style presets (save your combinations)
- Multi-line text with line height control
- Background color/gradient option (for full-bleed story export)
- Export as video (simple animated text reveal)
- Android launch

#### v2 — Story Composer (Weeks 9-16)
- Multi-layer canvas (multiple text blocks + images)
- Template library
- Brand kit (saved colors, fonts, logos)
- Curved text / text on path
- Google Fonts integration
- Cloud sync for fonts and presets

### Explicitly Deferred
- Font creation/glyph drawing (Pattern C) — until sticker demand is proven
- Video/animation in v1 — PNG is cheaper and sufficient
- Server-side rendering — everything local in v1
- User accounts / auth — no backend in v1
- Social features, sharing beyond Instagram
- Font marketplace / store
- Android in v1 (ship iOS first, validate, then port)

---

## 3. /build — MVP Architecture

### Target Platform: iOS First

**Why iPhone-first:**
- Instagram's heaviest creator demographic is iOS
- iOS sharing to Stories via URL scheme + pasteboard is the most documented path
- Design-conscious users (the target) skew iOS
- Faster to polish one platform than to debug two

### Tech Stack: Flutter

**Why Flutter over native Swift or React Native:**

| Factor | Flutter | Swift (native) | React Native |
|---|---|---|---|
| Cross-platform later | Built in | Rewrite for Android | Built in |
| Font rendering quality | Skia engine — excellent | Core Text — excellent | Bridge to native — variable |
| Runtime font loading | `FontLoader` API — documented | `CTFontManager` — documented | Expo-font, less reliable |
| Canvas/image export | `RenderRepaintBoundary.toImage()` | Core Graphics — excellent | Requires native modules |
| Time to MVP | **Fast** — hot reload, single codebase | Medium — UIKit/SwiftUI only | Medium — bridge debugging |
| Instagram share handoff | Platform channel (thin) | Native — trivial | Native module required |
| Will it slow shipping? | **No** — rendering + export are all Flutter-layer | N/A | Possibly — bridge issues |

**Key Flutter advantage:** The entire rendering pipeline (font → styled text → PNG) happens in Flutter's Skia engine. No bridge calls needed for the core feature. Only Instagram share handoff requires a thin platform channel.

### Architecture Diagram

```
┌─────────────────────────────────────────────────────────┐
│                     GLYPH APP                           │
│                                                         │
│  ┌──────────┐  ┌──────────────┐  ┌──────────────────┐  │
│  │  FONT    │  │   CANVAS     │  │   EXPORT         │  │
│  │  ENGINE  │  │   RENDERER   │  │   PIPELINE       │  │
│  │          │  │              │  │                  │  │
│  │ • Picker │  │ • Text input │  │ • PNG render     │  │
│  │ • Loader │  │ • Font apply │  │ • Camera roll    │  │
│  │ • Valid. │  │ • Style ctrl │  │ • IG share       │  │
│  │ • Cache  │  │ • Live prev. │  │                  │  │
│  └────┬─────┘  └──────┬───────┘  └────────┬─────────┘  │
│       │               │                    │            │
│  ┌────▼───────────────▼────────────────────▼─────────┐  │
│  │              STATE MANAGEMENT (Riverpod)           │  │
│  │  • FontState  • CanvasState  • ExportState        │  │
│  └───────────────────┬───────────────────────────────┘  │
│                      │                                  │
│  ┌───────────────────▼───────────────────────────────┐  │
│  │              LOCAL STORAGE                         │  │
│  │  • Font files (app documents dir)                 │  │
│  │  • User prefs (SharedPreferences)                 │  │
│  │  • Recent exports (cache dir)                     │  │
│  └───────────────────────────────────────────────────┘  │
│                                                         │
│  ┌───────────────────────────────────────────────────┐  │
│  │           PLATFORM CHANNELS (thin)                │  │
│  │  iOS: instagram-stories://share + UIPasteboard    │  │
│  │  Android: Intent ADD_TO_STORY (v1.5)              │  │
│  └───────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

### Rendering Stack

```
Font File (TTF/OTF)
    │
    ▼
FontLoader.load() → registers font family
    │
    ▼
TextPainter(text: TextSpan(style: TextStyle(fontFamily: loaded)))
    │
    ▼
RepaintBoundary → RenderRepaintBoundary.toImage(pixelRatio: 3.0)
    │
    ▼
image.toByteData(format: ui.ImageByteFormat.png)
    │
    ▼
Uint8List PNG with alpha channel
    │
    ├──▶ Save to Photos (image_gallery_saver)
    └──▶ Share to Instagram (platform channel → pasteboard → URL scheme)
```

### Font Ingestion Flow

1. User taps "Import Font"
2. `file_picker` opens iOS document picker (supports .ttf, .otf)
3. File copied to app's documents directory
4. Font validated: attempt `FontLoader.load()` — if it fails, show error
5. Font registered with a generated family name
6. Font metadata extracted (name, style) for display
7. Font added to local font list (persisted via SharedPreferences)

### Text Styling Model

```dart
class TextStyleModel {
  String fontFamily;        // loaded custom font family name
  double fontSize;          // 24-200pt range
  Color textColor;          // full RGBA color picker
  TextAlign alignment;      // left, center, right
  double letterSpacing;     // -5 to 20
  double lineHeight;        // 0.8 to 3.0 (v1.5)
  // v1.5 additions:
  // Color? strokeColor;
  // double strokeWidth;
  // Shadow? shadow;
}
```

### Export Pipeline

**PNG Export (v1 — cheap, fast, reliable):**
1. `RepaintBoundary` wraps the text render widget
2. `boundary.toImage(pixelRatio: 3.0)` → captures at 3x for retina quality
3. Convert to PNG bytes via `image.toByteData(format: ImageByteFormat.png)`
4. Result: transparent PNG, sized to text bounding box (not full 1080×1920)
5. For sticker use: keep tight to text bounds (Instagram will let user position/resize)
6. For full-bleed use: render on 1080×1920 canvas with optional background

**Instagram Share Handoff (iOS):**
```swift
// Platform channel handler (Swift side)
let pasteboardItems: [[String: Any]] = [[
    "com.instagram.sharedSticker.stickerImage": pngData,
    "com.instagram.sharedSticker.backgroundTopColor": "#000000",
    "com.instagram.sharedSticker.backgroundBottomColor": "#000000"
]]
UIPasteboard.general.setItems(pasteboardItems,
    options: [.expirationDate: Date().addingTimeInterval(60 * 5)])

let urlScheme = URL(string: "instagram-stories://share?source_application=\(fbAppId)")!
UIApplication.shared.open(urlScheme)
```

**Camera Roll Save:**
- Use `image_gallery_saver` package
- Save PNG to Photos library
- Request photo library permission on first save

### Local Storage Model

| Data | Storage | Location |
|---|---|---|
| Imported font files | File system | `getApplicationDocumentsDirectory()/fonts/` |
| Font metadata list | SharedPreferences | JSON array of `{name, family, path, dateAdded}` |
| User preferences | SharedPreferences | Theme, last used font, etc. |
| Bundled fonts | Asset bundle | `assets/fonts/` |
| Export cache | Cache directory | Temp — cleared periodically |

### Analytics/Events (v1 — minimal, local-first)

No analytics SDK in v1. Track locally for debugging:
- `font_imported` — font name, file size, success/failure
- `text_exported` — export type (png/save/share), font used, text length
- `ig_share_attempted` — success/failure
- `app_session` — duration, fonts used

Add Firebase Analytics in v1.5 after validating product-market fit.

### Failure Handling

| Failure | Handling |
|---|---|
| Invalid font file | Show error: "This font file couldn't be loaded. Try a different .ttf or .otf file." |
| Font with no glyphs for input text | Show fallback rendering + warning: "Some characters aren't available in this font." |
| Instagram not installed | Show message: "Instagram isn't installed. Save to camera roll instead?" + auto-save |
| Instagram share fails silently | Always save to camera roll as backup before share attempt |
| Export OOM on large canvas | Limit canvas to 1080×1920 max, limit text size to reasonable bounds |
| Photo library permission denied | Show Settings deep link: "Allow photo access to save your stickers." |

### Licensing / Compliance

**This is product-critical, not legal fine print.**

| Concern | Handling |
|---|---|
| Users importing commercial fonts they own | Show one-time notice: "Make sure you have the right to use this font for social media." |
| Users importing pirated fonts | Not our problem to police, but clear notice shifts liability |
| Bundled fonts | Use ONLY OFL (SIL Open Font License) fonts — free for any use |
| Font redistribution | App never shares font files — only rendered images |
| Instagram's ToS | Sharing images/stickers via documented API — fully compliant |

**Bundled font sources (all OFL):**
- Google Fonts (curated selection of 3-5 display fonts)
- Example picks: Playfair Display, Space Grotesk, Archivo Black, Caveat, DM Serif Display

---

## 4. /product — MVP UX Design

### Design Philosophy

Inspired by **iA Writer** (typography IS the interface), **Things 3** (every interaction is delightful), and **Bakken & Baeck** (craft in every pixel):

- **One screen, one purpose.** The canvas IS the app. No tabs, no navigation hierarchy.
- **Typography-first.** The font preview is the hero — not buttons, not chrome.
- **Progressive disclosure.** Styling controls are tucked away until needed (Things pattern).
- **Instant gratification.** First useful output in under 30 seconds from cold open.

### The Exact 1-Screen Prototype Scope

```
┌──────────────────────────────────┐
│  [Font Picker ▾]    [Export ↗]   │  ← Minimal top bar
│                                  │
│                                  │
│                                  │
│                                  │
│         Your text here           │  ← Live preview, tappable to edit
│         in your font             │  ← Renders with selected custom font
│                                  │
│                                  │
│                                  │
│                                  │
│  ┌──────────────────────────────┐│
│  │  Aa  │  🎨  │  ↔  │  ≡     ││  ← Style bar: size, color, spacing, align
│  └──────────────────────────────┘│
│  ┌──────────────────────────────┐│
│  │  + Import Font               ││  ← Font import CTA
│  └──────────────────────────────┘│
└──────────────────────────────────┘
```

### Main User Flow: App Open → Instagram Handoff

```
1. OPEN APP
   → See canvas with "Type something" placeholder in bundled font
   → Keyboard auto-appears on first launch

2. TYPE TEXT
   → Live preview updates as you type
   → Text renders in currently selected font

3. PICK FONT (optional)
   → Tap font picker → see list of imported + bundled fonts
   → Each font shown as preview of current text
   → Tap to select → canvas updates instantly

4. STYLE TEXT (optional)
   → Swipe up or tap style bar
   → Adjust: size (slider), color (grid + custom), spacing (slider), alignment (3 buttons)
   → All changes preview live

5. EXPORT
   → Tap export button → bottom sheet:
     • "Share to Instagram Stories" (primary, bold)
     • "Save to Photos" (secondary)
     • "Copy Image" (tertiary)
   → Instagram: renders PNG → pasteboard → opens Instagram → sticker appears
   → Save: renders PNG → saves to camera roll → confirmation toast

6. DONE
   → User is in Instagram Stories with their custom font sticker
   → Total time: 15-30 seconds
```

### Screen-by-Screen Breakdown (MVP)

**Screen 1: Canvas (Main — and only — screen)**
- Full-screen dark canvas (dark gray, not black — feels premium)
- Center-aligned text preview area
- Text input via system keyboard (tap canvas to toggle)
- Top bar: font picker dropdown (left), export button (right)
- Bottom: style control bar (collapsed by default)
- Below style bar: "Import Font" button when < 3 fonts imported

**Sheet 1: Font Picker**
- Bottom sheet, 40% height
- Search bar at top
- Section: "Your Fonts" (imported), "Built-in" (bundled)
- Each row: font name rendered in that font + "..." menu (delete, info)
- "Import Font" button at bottom

**Sheet 2: Export**
- Bottom sheet, compact
- Three options as large tappable rows with icons
- Primary action (IG Stories) is visually emphasized
- Shows tiny preview thumbnail of the export

**Sheet 3: Color Picker**
- Bottom sheet
- Preset color grid (16 curated colors, including white, common brand colors)
- Custom color: HSB wheel or hex input
- Recent colors row

### Controls INCLUDED in v1

| Control | Type | Range |
|---|---|---|
| Font selection | Picker | Imported + bundled fonts |
| Font size | Slider | 24pt – 200pt |
| Text color | Color picker | Full RGBA |
| Letter spacing | Slider | -5 to +20 |
| Text alignment | 3 buttons | Left / Center / Right |

### Controls EXCLUDED from v1

| Control | Why Deferred |
|---|---|
| Line height | Single-line is enough for stickers |
| Stroke/outline | Adds rendering complexity |
| Drop shadow | Adds rendering complexity |
| Gradient text | Shader complexity |
| Curved text | Path rendering complexity |
| Multiple text blocks | Turns into compositor — Pattern B |
| Background image | Turns into compositor — Pattern B |
| Animation/video | Encoding complexity |
| Opacity | Minor — add in v1.5 |

### Onboarding Flow

**First launch:**
1. Splash: app icon + name, 1 second
2. Canvas appears with "Hello" typed in bundled display font (Playfair Display)
3. Pulsing hint on text: "Tap to type your own text"
4. After first text entry, gentle hint on font picker: "Try a different font"
5. After first font pick, hint on export: "Share to Instagram"
6. That's it. Three progressive hints. No tutorial screens.

**Why no onboarding wizard:** The app does one thing. The interface teaches itself. iA Writer doesn't need a tutorial — neither should this.

### Font Import Flow

1. Tap "Import Font" or "+" in font picker
2. iOS document picker opens, filtered to .ttf and .otf files
3. User selects file
4. Loading spinner (< 1 second typically)
5. **Success:** Font appears in picker, auto-selected, text preview updates. Toast: "Font loaded!"
6. **Failure:** Alert: "Couldn't load this font file. Make sure it's a valid .ttf or .otf."
7. **First import only:** One-time notice: "Make sure you have the right to use this font for social media content."

### Export Flow

1. Tap export button (top right)
2. Bottom sheet appears with export options
3. **Share to Instagram Stories:**
   - Render transparent PNG
   - Copy to pasteboard with Instagram sticker keys
   - Open `instagram-stories://` URL scheme
   - If Instagram not installed → fallback to Save + message
4. **Save to Photos:**
   - Render transparent PNG
   - Save to Photos library via `image_gallery_saver`
   - Toast: "Saved to Photos!"
   - On first save, system permission prompt appears
5. **Copy Image:**
   - Render transparent PNG
   - Copy to system clipboard
   - Toast: "Copied!"

### Empty / Error States

| State | Display |
|---|---|
| No text entered | Placeholder: "Type something" in selected font, 40% opacity |
| No fonts imported | Bundled fonts still available — never truly "empty" |
| Font load failure | Alert with retry/dismiss, stays on previous font |
| Instagram not installed | "Instagram isn't installed. Save to camera roll and add it to your story manually." |
| Export failure | "Something went wrong. Your image has been saved to Photos as a backup." |
| Photo permission denied | "Allow photo access in Settings to save stickers." + Settings button |

### The Smallest Lovable Version

**Genuinely useful in one sitting:**
- Type "SALE" in a bold custom font → export → add to story announcing a sale. Done.
- Type your brand name → export → use as a consistent watermark on every story.
- Type a quote in an elegant serif → export → share.

**Feels premium even though feature set is tiny:**
- Dark canvas with generous whitespace (iA Writer)
- Smooth font switching with instant preview (Things-level responsiveness)
- Subtle haptic feedback on export (tactile craft)
- The *font preview in the picker* renders your actual text, not "AaBbCc" (thoughtful detail)
- Export animation: brief, satisfying scale-down-and-fly-out to Instagram (delightful)
- High-quality text rendering — antialiased, proper kerning, respects font metrics

---

## 5. /execution — Build Plan

### 2-Week Prototype Plan (Prove Viability)

**Goal:** Prove the three critical unknowns: font loads → text renders → sticker lands in Instagram.

| Day | Task | Deliverable |
|---|---|---|
| 1 | Flutter project setup, dependencies, directory structure | Running app shell |
| 2 | Font loading: file_picker + FontLoader, test with 5 TTF files | Fonts load at runtime |
| 3 | Text rendering canvas: TextPainter on RepaintBoundary | Text displays in custom font |
| 4 | Styling controls: size slider, color picker, alignment | Styled text preview |
| 5 | PNG export: toImage() → PNG bytes with transparency | Valid transparent PNG |
| 6 | Camera roll save via image_gallery_saver | PNG appears in Photos |
| 7 | Instagram share: platform channel, pasteboard, URL scheme | Sticker lands in IG Stories |
| 8 | End-to-end test: type → style → export → Instagram | Full flow works |
| 9 | Fix bugs, handle edge cases, test with 10+ fonts | Robust prototype |
| 10 | Polish: dark theme, basic layout, haptics | Demo-ready prototype |

**"Stop if this fails" gate (Day 7):**
- Can a custom TTF render to transparent PNG and appear as a movable sticker in Instagram Stories?
- If YES → proceed to MVP
- If NO (alpha not preserved, Instagram rejects sticker, crashes) → investigate workarounds for 2 days, then stop if unresolvable

### 4-Week MVP Plan

| Week | Focus | Milestone |
|---|---|---|
| **Week 1** | Core engine | Font loading + text rendering + PNG export pipeline working end-to-end |
| **Week 2** | Instagram handoff + camera roll | Full export flow: render → save → share to Instagram Stories |
| **Week 3** | UX polish + styling controls | One-screen canvas with font picker, size/color/spacing/alignment, dark theme |
| **Week 4** | Bundled fonts, onboarding, error handling, TestFlight | Beta-ready build with 3-5 bundled fonts, progressive onboarding hints, all error states handled |

### Critical Path

```
Font Loading → Text Rendering → PNG Export → Instagram Share
     ↓              ↓               ↓              ↓
   Day 2          Day 3           Day 5          Day 7
```

Everything else (styling, polish, onboarding) is parallelizable and non-blocking. The critical path is the rendering pipeline + Instagram handoff.

### Technical Spikes (Do Before Committing)

| Spike | Question | Time |
|---|---|---|
| Font loading | Does `FontLoader` handle all common TTF/OTF variants? Edge cases? | 4 hours |
| Alpha export | Is alpha channel preserved in `toImage()` → PNG pipeline? | 2 hours |
| Instagram sticker | Does the sticker appear correctly sized and movable in Stories? | 4 hours |
| Font validation | What happens with corrupt/incomplete font files? | 2 hours |
| Memory | How much RAM does loading 20+ custom fonts consume? | 2 hours |

### Demo Checkpoints

| Checkpoint | Date | What to Show |
|---|---|---|
| Spike complete | Day 3 | Custom font renders to image, alpha preserved |
| Instagram proof | Day 7 | End-to-end: type → export → sticker in Instagram |
| MVP alpha | Day 14 | Full styled canvas with font picker and export |
| Beta ready | Day 28 | Polished app, bundled fonts, error handling, TestFlight |

### Top Risks and Mitigations

| # | Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|---|
| 1 | Instagram changes/breaks Sharing to Stories API | Low | Critical | Always offer camera roll save as fallback; monitor Meta developer changelog |
| 2 | Alpha transparency lost in PNG pipeline | Low | High | Test early (Day 5 spike); if Flutter's pipeline strips alpha, use `dart:ui` Canvas directly |
| 3 | Flutter `FontLoader` can't handle some TTF variants | Medium | Medium | Validate on load, reject gracefully; test with 50+ real fonts |
| 4 | Instagram sticker sizing is wrong (too big/small) | Medium | Medium | Test multiple sizes; provide size guidance; let IG composer handle resize |
| 5 | App Store rejection for IP/licensing concerns | Low | High | Clear licensing notice, no font redistribution, only export rendered images |
| 6 | No one cares about custom fonts in Stories | Medium | Critical | Validate with creator community before building past prototype; run landing page test |
| 7 | Facebook App ID registration takes too long | Low | Medium | Register immediately on Day 1; takes ~24 hours typically |
| 8 | Memory pressure from multiple loaded fonts | Low | Medium | Lazy-load fonts; limit concurrent loaded fonts; test on iPhone SE |

---

## 6. /test — Validation Plan

### Binary Truth Gates

| # | Test | Pass Criteria | Method | Automated? |
|---|---|---|---|---|
| 1 | Custom TTF loads | Font renders "Hello World" with correct glyphs | Unit test + visual | Partial |
| 2 | Custom OTF loads | Same as above with OTF | Unit test + visual | Partial |
| 3 | Text spacing correct | Letter spacing slider changes spacing measurably | Visual inspection | Manual |
| 4 | Stroke/shadow renders (v1.5) | Visible stroke/shadow on exported image | Visual inspection | Manual |
| 5 | Transparent PNG exports | Exported PNG has alpha channel; background is transparent | Programmatic check on PNG bytes | **Yes** |
| 6 | Image dimensions correct | Sticker PNG is proportional, reasonable resolution (e.g., 1080px wide max) | Programmatic check | **Yes** |
| 7 | Camera roll save works | PNG appears in iOS Photos library | Manual test | Manual |
| 8 | Instagram share opens IG | `instagram-stories://` URL scheme opens Instagram | Manual test | Manual |
| 9 | Sticker appears in composer | Exported sticker is visible, movable, resizable in IG Stories | Manual test | Manual |
| 10 | Sticker transparency preserved in IG | Background shows through transparent areas of sticker in IG | Manual test | Manual |
| 11 | Performance on mid-tier device | Export completes in < 2 seconds on iPhone 12 | Timed test | Manual |
| 12 | Memory stays reasonable | Peak memory < 200MB with 10 fonts loaded | Instruments profiling | Manual |
| 13 | Font licensing notice shown | First import shows licensing notice | UI test | **Yes** |
| 14 | Invalid font rejected gracefully | Corrupt file shows error, doesn't crash | Unit test | **Yes** |
| 15 | Instagram not installed fallback | Shows save-to-camera-roll message | UI test | **Yes** |

### Manual Testing Protocol

1. **Font compatibility matrix:** Test with 20 fonts (10 TTF, 10 OTF) from Google Fonts, DaFont, and commercial sources. Log: loads/fails, rendering quality, kerning accuracy.
2. **Device matrix:** Test on iPhone SE (3rd gen), iPhone 14, iPhone 15 Pro Max. Check: performance, layout, memory.
3. **Instagram version matrix:** Test with current Instagram + one version back. Check: share handoff, sticker behavior.
4. **Edge cases:** Empty text, very long text (500+ chars), emoji in text, RTL text (Arabic/Hebrew), CJK characters.

### Evidence That Proves MVP Is Viable

1. **Technical proof:** Custom TTF → transparent PNG → Instagram sticker, working end-to-end on 3 devices
2. **Quality proof:** 18/20 test fonts render correctly with proper kerning
3. **Speed proof:** Type → export → Instagram in under 30 seconds, measured
4. **Stability proof:** Zero crashes in 50 consecutive export cycles
5. **User proof:** 5 creators try the prototype and successfully use it in a real story

---

## 7. /review — Critical Analysis

### Where This Could Fail Commercially
- **Market size uncertainty.** How many creators actually want custom fonts badly enough to install a separate app? Instagram's built-in fonts are "good enough" for 95% of users.
- **Workflow friction.** Switching between apps (Glyph → Instagram) is inherently more friction than typing directly in Instagram. The sticker can't be edited once placed.
- **Canva/Unfold competition.** Canva's story maker already supports custom fonts in a full compositor. Glyph's advantage is speed and focus, but Canva has distribution.
- **One-trick pony risk.** A sticker maker might not have enough depth for retention. Users might use it once and forget.

### Where This Could Fail Technically
- **Instagram API instability.** Meta can change or deprecate the Sharing to Stories API without notice. This has happened before with other APIs.
- **Font rendering edge cases.** Variable fonts, color fonts (like emoji fonts), complex scripts (Arabic, Devanagari) may not render correctly in Flutter.
- **PNG size limits.** Very large text at high resolution could create PNGs that are slow to export or that Instagram handles poorly.

### Where Users May Not Care Enough
- **Casual story posters** don't think about typography at all. The target is specifically brand-conscious creators, small business owners, and designers — a niche within a niche.
- **"Good enough" syndrome.** Many creators use Canva, Over, or other tools that already have decent font support. Custom fonts from their own files is a sub-need.

### Why "Font Builder" Is Too Early
- Font creation is a completely different discipline requiring glyph editors, kerning tables, hinting, OpenType feature support — months of specialized work.
- The user base for "I want to create a font" is 100x smaller than "I want to use my font in Stories."
- Building a font editor before proving sticker demand is the classic startup mistake of building infrastructure before product-market fit.

### What Wedge Could Still Make It Work
- **Speed as the wedge.** If Glyph can get a custom font sticker into Stories in 10 seconds vs. 2 minutes in Canva, that's a real wedge for power users who post daily.
- **Font library as retention.** Users who import 5-10 brand fonts have switching costs. Their font library becomes the moat.
- **Creator workflow integration.** If Glyph becomes the "font tool" in the creator toolkit (like Lightroom for photos), there's a daily-use case.
- **Expand the export surface.** Stickers for TikTok, Threads, YouTube Shorts, etc. — same transparent PNG, different share targets.

---

## 8. /ship — Final Recommendation

### The Exact v1 to Build

**Glyph v1: Font Sticker Maker for Instagram Stories**

A single-screen iOS app. Type text, pick your font, style it (size, color, spacing, alignment), export as transparent PNG sticker directly into Instagram Stories or save to camera roll. Ships with 3-5 bundled display fonts. Supports importing TTF/OTF from device files.

### Target Platform
**iOS (iPhone) only for v1.** Android in v1.5 after validating demand.

### Tech Stack
- **Framework:** Flutter (Dart)
- **State management:** Riverpod
- **Font loading:** `FontLoader` + `file_picker`
- **Rendering:** `RepaintBoundary` + `dart:ui`
- **Export:** `image_gallery_saver` + custom platform channel for Instagram
- **Storage:** Local filesystem + SharedPreferences
- **Backend:** None
- **Analytics:** None in v1 (local debug logging only)

### The First Prototype to Code This Week

**Day 1-3:** Build the font loading → text rendering → PNG export pipeline. One Dart file, no UI polish, just prove the three steps work.

```
main.dart:
  1. Load a TTF from assets
  2. Render "Hello World" in that font on a transparent canvas
  3. Export to PNG
  4. Verify alpha channel is present
  5. Share to Instagram Stories
```

If this works by Day 3, the product is buildable.

### The Single Biggest Thing to Avoid

**Do not build a story compositor.** The moment you add layers, backgrounds, templates, or multiple text blocks, you're competing with Canva with 1/10000th the resources. Pattern A wins by being fast and focused. The entire UX should be completable in 15 seconds. If it takes longer than opening Canva, you've lost.

---

## Risk Register (Summary)

| # | Risk | Severity | Probability | Mitigation |
|---|---|---|---|---|
| R1 | Instagram API deprecated/changed | Critical | Low | Camera roll fallback always works; expand to TikTok/Threads share |
| R2 | Alpha transparency not preserved | High | Low | Day 5 spike; fallback to white background option |
| R3 | Flutter FontLoader incompatible with some fonts | Medium | Medium | Validate + reject gracefully; test 50+ fonts |
| R4 | No product-market fit | Critical | Medium | Landing page test before full build; share prototype with 10 creators |
| R5 | App Store rejection | High | Low | Clear licensing UI; no font redistribution; only rendered images shared |
| R6 | Canva adds "quick sticker" mode | Medium | Medium | Ship fast; own the speed niche; build font library moat |
| R7 | Facebook App ID registration delays | Medium | Low | Register Day 1; only blocks Instagram share, not core build |
| R8 | Memory issues with many fonts | Medium | Low | Lazy loading; cap at 50 fonts; test on low-end devices |

---

## Go / No-Go Recommendation

**GO** — with the following conditions:

1. Register Facebook App ID today (Day 0)
2. Complete the font → PNG → Instagram spike by Day 3
3. If the spike fails on alpha transparency or Instagram handoff, spend 2 days on workarounds
4. If workarounds fail, **NO-GO** — the core value prop doesn't work
5. If spike passes, commit to the 4-week MVP plan
6. Ship TestFlight beta by Week 4
7. Get 5 real creators using it before any further investment

**The bar for shipping is low: one screen, one purpose, under 30 seconds from open to Instagram.** If it can't clear that bar, nothing else matters.
