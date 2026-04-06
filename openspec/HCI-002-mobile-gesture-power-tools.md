# HCI-002: Mobile Gesture Power Tools

**Status:** Proposed
**Author:** Claude
**Date:** 2026-04-06
**Scope:** ios-native/Glyph — Gesture Interaction, Undo/Redo, Color UX, Custom Guides, Export Preview
**Depends on:** HCI-001 (completed)

---

## 1. Objective

Glyph is a mobile-first design tool. The canvas lives and dies by touch —
pinching, dragging, sliding, double-tapping. Right now gestures are
functional but *dumb*: rotation ignores cardinal angles, there's no undo,
color picking is a flat grid with no nuance, and the only guides are
canned overlays. This spec levels up every touch surface to feel like a
real design tool — the kind where your thumbs do the thinking.

**Design north stars:** iA Writer focus, Things clarity, Figma snap-smoothness,
Procreate gesture economy.

---

## 2. Problem Statements

### 2.1 Rotation has no "feel"

Rotating a layer is a free-form pinch with zero tactile anchors. Users
can't quickly hit 0°, 90°, 180°, 270°. There's no haptic click at
cardinal angles. The result is fiddly, imprecise, and feels cheap.

### 2.2 Double-tap does nothing useful

A double-tap on a text layer enters edit mode, but on an image layer it
does nothing. On *any* layer a double-tap should do something instantly
gratifying — snap rotation to the nearest 90°, or reset the transform.

### 2.3 No undo/redo

Every design tool since MacPaint has undo. Glyph doesn't. A slip of the
finger moves a carefully positioned layer and there's no way back. This
is the #1 trust killer for a creative tool.

### 2.4 Color picker is flat and narrow

The ColorGrid is a static 16-swatch grid. No HSB wheel, no recent colors,
no eyedropper, no way to pick a color that isn't in the preset list.
For a tool whose primary output is visual, this is a big gap.

### 2.5 Snap threshold is a mystery number

Settings shows "Snap Threshold: 8 pt" with a slider. Nobody knows what
8pt *means*. There's no visual representation of the snap zone while
dragging. It's a setting for the sake of having a setting.

### 2.6 No custom guides

Users can toggle an even grid, rule of thirds, or golden ratio — but
can't drag their own guide lines onto the canvas. Every serious design
tool (Figma, Sketch, Photoshop) lets you pull horizontal/vertical ruler
guides. Glyph should too.

### 2.7 No export preview

The ExportSheet renders the image silently and shares it. Users have to
blindly trust the output. There's no "here's what you'll get" preview.

### 2.8 Chrome needs iA Writer polish

The toolbar, controls, and sheets work but don't feel *considered*.
iA Writer's magic is that the UI disappears while you work. Glyph's UI
should recede the same way — minimal chrome, generous negative space,
and interactions that happen at the fingertip, not behind a sheet.

---

## 3. Design Decisions

| # | Decision | Rationale |
|---|----------|-----------|
| D1 | Rotation snap at 0°, 90°, 180°, 270° with 5° threshold | Matches Procreate; narrow enough to not trigger accidentally, wide enough to feel magnetic |
| D2 | Haptic `.selectionChanged()` at each cardinal angle tick | Subtle "click" without the jarring `.impactOccurred` — matches iOS Camera rotation |
| D3 | Double-tap snaps to nearest 90° (image) / enters edit (text) | Consistent mental model: double-tap = "do the obvious next thing" |
| D4 | Undo stack: 50 states, differential snapshots | Store full `CanvasState` snapshots (layers array + background). 50 is generous for mobile; avoids partial-state bugs of command pattern |
| D5 | Shake-to-undo supported via iOS system gesture | `UIResponder.undoManager` integration — users already know this from iOS |
| D6 | Color picker: HSB wheel + recent colors + eyedropper | Wheel for exploration, swatches for speed, eyedropper for precision. Replace flat grid with tabbed picker |
| D7 | Snap zone visualized as translucent band on drag | When dragging, show the threshold as a faint band around guide lines — makes the setting tangible |
| D8 | Custom guides: drag from ruler edges | Tap+drag from canvas edges creates persistent guide lines. Tap existing guide to delete. Stored per-canvas in CanvasViewModel |
| D9 | Export preview: rendered thumbnail in ExportSheet | Show a scaled-down 9:16 preview of the final render above the action buttons. Re-renders on sheet appear, not on every change |
| D10 | Toolbar auto-hides after 3s of canvas interaction | Maximizes canvas area. A single tap on empty canvas brings toolbar back (already wired to `deselectAll`) |

---

## 4. Implementation Plan

### 4.1 Rotation Snap (P0)

**Files:** `CanvasViewModel.swift`, `TextOverlayView.swift`, `ImageOverlayView.swift`, `HapticsService.swift`

- Add `RotationSnapEngine` as a namespace in `AlignmentEngine.swift`
  - `static func snap(_ angle: Angle, threshold: Angle = .degrees(5)) -> Angle?`
  - Returns the nearest cardinal angle if within threshold, else nil
  - Cardinals: [0°, 90°, 180°, 270°, -90°, -180°, -270°]

- In both overlay views, after `RotationGesture.onEnded`:
  ```swift
  let finalRotation = layer.rotation + value
  if let snapped = RotationSnapEngine.snap(finalRotation) {
      onRotationChange(snapped)
      haptics.rotationSnap()
  } else {
      onRotationChange(finalRotation)
  }
  ```

- Add `rotationSnap()` to `HapticsService`:
  ```swift
  func rotationSnap() { select.selectionChanged() }
  ```

- During live rotation (`.updating`), provide a subtle haptic tick when
  crossing cardinal angles. Track last snapped angle in `@GestureState`.

- Show degree label while rotating: overlay "90°" text near the layer.
  Fade in on rotation start, fade out 0.5s after gesture ends.

### 4.2 Double-Tap (P0)

**Files:** `TextOverlayView.swift`, `ImageOverlayView.swift`

- Replace `.onTapGesture` with a `TapGesture(count: 2).sequenced(before: TapGesture(count: 1))`:
  - Single tap: select (existing behavior)
  - Double tap on text layer: enter edit mode (existing behavior, just route differently)
  - Double tap on image layer: snap rotation to nearest 90°

- In `ImageOverlayView`, add:
  ```swift
  .onTapGesture(count: 2) {
      if let snapped = RotationSnapEngine.snap(layer.rotation) {
          onRotationChange(snapped)
          haptics.rotationSnap()
      }
  }
  .onTapGesture { onSelect() }
  ```

- On both: double-tap when already at a cardinal angle resets rotation to 0°.
  This gives a quick "straighten out" gesture.

### 4.3 Undo/Redo (P0)

**Files:** New `UndoManager+Canvas.swift` in Engine/, `CanvasViewModel.swift`, `CanvasView.swift`

- Define `CanvasState` snapshot:
  ```swift
  struct CanvasState: Codable {
      let layers: [LayerSnapshot]
      let background: BackgroundSnapshot?
  }
  ```
  LayerSnapshot is a codable enum wrapper over TextLayer/ImageLayer data.
  BackgroundSnapshot stores image data + scale + offset.

- Add `UndoStack` class to CanvasViewModel:
  ```swift
  private var undoStack: [CanvasState] = []
  private var redoStack: [CanvasState] = []
  private let maxUndoStates = 50
  ```

- Call `pushUndoState()` before every mutation (position, scale, rotation,
  text, color, layer add/remove, background change).

- Expose:
  ```swift
  var canUndo: Bool { !undoStack.isEmpty }
  var canRedo: Bool { !redoStack.isEmpty }
  func undo()
  func redo()
  ```

- UI: Add undo/redo buttons to bottom controls (visible when a layer is
  selected). Icons: `arrow.uturn.backward` / `arrow.uturn.forward`.
  Keyboard: Cmd+Z / Cmd+Shift+Z (already works with UIResponder
  undoManager, but we add explicit buttons for touch users).

- Shake-to-undo: wire `UIResponder.current?.undoManager` or listen for
  `UIEvent.EventSubtype.motionShake`.

### 4.4 Color Picker (P1)

**Files:** New `ColorPickerView.swift` in Views/, updated `StyleControlsView.swift`

- Replace `ColorGrid` usage in StyleControlsView with `ColorPickerView`.

- `ColorPickerView` is a tabbed container:
  - **Tab 1: Palette** — existing `ColorGrid` (renamed, unchanged internally)
  - **Tab 2: Wheel** — `ColorWheelView` using HSB conic gradient Canvas
  - **Tab 3: Eyedropper** — reads pixel color from a screenshot of the canvas

- **ColorWheelView:**
  - Draws a conic hue ring + brightness/saturation square (classic HSB)
  - Drag to pick; live preview swatch updates continuously
  - Supports Dynamic Type via semantic labels

- **Recent colors:**
  - Store last 8 picked colors in `SettingsViewModel.recentColors`
  - Persisted to UserDefaults as `[String]` (hex values)
  - Displayed as a horizontal strip below the tab picker

- Eyedropper:
  - Captures current canvas as UIImage
  - Shows a magnifier loupe that follows the finger
  - On release, picks the pixel color and sets it
  - Requires `canvasScreenshot()` method on `ExportEngine` — reuse
    existing render with a smaller output size for performance

### 4.5 Snap UX — Visual Threshold (P1)

**Files:** `GuidesOverlayView.swift`, `CanvasViewModel.swift`

- When `!activeGuides.isEmpty`, render translucent bands around each
  active guide line showing the snap zone width (`snapThreshold * 2`):
  ```
  guide line (solid 1pt)
  band (fill, opacity 0.06, width = snapThreshold * 2)
  ```

- This makes the snap threshold *visible* — users can see the magnetic
  zone and understand what the slider in Settings does.

- Add a "feel" label in Settings snap threshold section:
  " tighter ← — → more magnetic "
  instead of just "8 pt". Keep the number but add the analogy.

### 4.6 Custom Ruler Guides (P1)

**Files:** New `CustomGuidesOverlay.swift` in Views/, updated `CanvasViewModel.swift`, `GuidesOverlayView.swift`

- **Data model:**
  ```swift
  struct CustomGuide: Identifiable, Codable {
      let id: UUID
      let axis: GuideAxis // .horizontal or .vertical
      var position: CGFloat // offset from canvas center, same coordinate system as AlignmentEngine
  }
  ```

- Add to `CanvasViewModel`:
  ```swift
  var customGuides: [CustomGuide] = []
  func addCustomGuide(_ guide: CustomGuide)
  func removeCustomGuide(id: UUID)
  func moveCustomGuide(id: UUID, to position: CGFloat)
  ```

- **Ruler edges:** When guides overlay is visible, render thin ruler strips
  (12pt tall) along top and left edges of the canvas. Dragging from
  these strips creates a new guide.

- **Interaction:**
  - Drag from top ruler → horizontal guide follows finger vertically
  - Drag from left ruler → vertical guide follows finger horizontally
  - Release to place
  - Tap an existing custom guide to select it (turns accent color)
  - Drag to reposition
  - Drag off-canvas or tap delete button to remove

- **Snapping:** Custom guides participate in `AlignmentEngine.snapPosition`
  alongside built-in guides. Add them to `otherLayerGeometries`-equivalent
  in the snap calculation.

- **Persistence:** Custom guides are saved per-session (in memory). Could
  later be persisted per-project, but for now they reset on app close
  (same as layer state).

### 4.7 Export Preview (P2)

**Files:** `ExportSheet.swift`

- Add a `@State var previewImage: UIImage?` to ExportSheet.

- On `.onAppear` / `.task`, render the canvas at a preview size
  (360×640 — 1/3 of export resolution) and set `previewImage`.

- Display the preview as a scaled `Image(uiImage:)` with rounded corners
  and a subtle shadow, centered above the action buttons.

- Layout:
  ```
  ┌─────────────────────────────┐
  │  EXPORT                      │
  │                              │
  │  ┌───────────────────────┐   │
  │  │                       │   │
  │  │   9:16 Preview        │   │
  │  │   (aspect-fit)        │   │
  │  │                       │   │
  │  └───────────────────────┘   │
  │                              │
  │  [ Share to Instagram     ]  │
  │  [ Save to Photos         ]  │
  │  [ Copy Image             ]  │
  └─────────────────────────────┘
  ```

- Increase sheet detent to `.height(480)` to accommodate the preview.

- Add a "Re-render" button below the preview (subtle, text-only) for
  when the user changes settings between preview and export.

### 4.8 iA Writer Design Polish (P2)

**Files:** `CanvasView.swift`, `GlyphDesignSystem.swift`, `StyleControlsView.swift`, `ExportSheet.swift`

- **Toolbar auto-hide:**
  - Add `@State private var toolbarVisible: Bool = true` to CanvasView
  - On canvas interaction start (drag gesture begins), start a 3-second
    timer. On fire, set `toolbarVisible = false`.
  - Tapping empty canvas sets `toolbarVisible = true` (already calls
    `deselectAll()`, just add the flag toggle).
  - Animate toolbar with `.transition(.move(edge: .top))` + `.opacity`.

- **Bottom controls:** Same auto-hide behavior. Controls slide down and
  fade out. Any bottom control tap brings them back for another 3s.

- **Selection handles:** Replace the dashed/solid `RoundedRectangle`
  selection border with iA Writer–style corner brackets:
  ```
  ┌                   ┐


  └                   ┘
  ```
  Only draw corners (8pt lines), not full border. Feels lighter.

- **Degree badge while rotating:** When a rotation gesture is active,
  show the current angle in a small pill badge above the layer:
  "45.2°" → snaps to "90°" with accent color when cardinal.

- **Sheet corner radius:** Ensure all sheets use `DS.Radius.lg` (14pt)
  for consistent softness matching iOS 18 aesthetic.

---

## 5. Acceptance Criteria

### 5.1 Rotation Snap
- [ ] Rotating a layer within 5° of 0°/90°/180°/270° snaps to that angle
- [ ] Haptic click fires when rotation snaps to a cardinal angle
- [ ] Degree badge appears during rotation and shows snapped angle
- [ ] VoiceOver announces "Snapped to 90 degrees" on cardinal snap

### 5.2 Double-Tap
- [ ] Double-tap on image layer snaps rotation to nearest 90°
- [ ] Double-tap on text layer enters edit mode
- [ ] Double-tap when already at cardinal angle resets to 0°
- [ ] Single tap still selects the layer (no regressions)

### 5.3 Undo/Redo
- [ ] Undo button appears in bottom controls; undoes last action
- [ ] Redo button appears after undo; redoes the action
- [ ] Stack depth: 50 states maximum; oldest silently dropped
- [ ] Shake-to-undo triggers undo
- [ ] Undo/redo correctly restores position, scale, rotation, text,
      color, layer add/remove, background changes
- [ ] Buttons disabled when stack is empty (no crash)

### 5.4 Color Picker
- [ ] Three tabs: Palette, Wheel, Eyedropper
- [ ] Palette tab shows existing ColorGrid swatches
- [ ] Wheel tab shows HSB color wheel; drag to pick
- [ ] Eyedropper tab captures canvas and picks pixel color
- [ ] Recent colors strip shows last 8 picked colors
- [ ] Selected color updates live in the canvas text

### 5.5 Snap UX
- [ ] Snap zone rendered as translucent band around active guides
- [ ] Band width matches `snapThreshold * 2`
- [ ] Settings shows descriptive label alongside numeric value

### 5.6 Custom Guides
- [ ] Ruler strips visible along top/left edges when guides overlay is on
- [ ] Drag from ruler strip creates a new guide line
- [ ] Tap+drag existing custom guide to reposition
- [ ] Tap custom guide + delete button to remove
- [ ] Custom guides participate in layer snap alignment
- [ ] VoiceOver: "Custom guide added", "Guide removed"

### 5.7 Export Preview
- [ ] ExportSheet shows scaled 9:16 preview of final render
- [ ] Preview renders on sheet appear (not on every change)
- [ ] "Re-render" button available to update preview
- [ ] Sheet detent accommodates preview + 3 action buttons

### 5.8 Design Polish
- [ ] Toolbar auto-hides after 3s of canvas interaction
- [ ] Tapping empty canvas shows toolbar again
- [ ] Selection borders use corner brackets, not full rectangles
- [ ] Degree badge shows during rotation gesture
- [ ] All changes respect `accessibilityReduceMotion`

---

## 6. Performance Budget

| Metric | Target | Measurement |
|--------|--------|-------------|
| Rotation snap haptic latency | < 16ms (1 frame) | Time from angle crossing to `selectionChanged()` |
| Undo state push | < 2ms | Time to snapshot and push onto stack |
| Color wheel drag FPS | ≥ 58fps | Instruments GPU frame time |
| Custom guide drag FPS | ≥ 58fps | Must not trigger full re-render |
| Export preview render | < 500ms | 360×640 render on iPhone 16 Pro |
| Toolbar auto-hide animation | 200ms ease-out | Reduce motion: instant hide/show |

---

## 7. Testing Strategy

- **Unit tests:** `RotationSnapEngineTests` — verify snap at 4°, 5°, 6° from each cardinal
- **Unit tests:** `UndoStackTests` — push, undo, redo, stack overflow, stack at boundary
- **Unit tests:** `CustomGuideTests` — add, remove, reposition, snap integration
- **Snapshot tests:** Export preview matches full render (scaled comparison)
- **Manual verification:**
  - Rotate layer slowly past 90° — feel haptic, see badge
  - Double-tap image layer — rotation snaps
  - Shake device — undo fires
  - Pull guide from ruler — guide appears and snaps layer
  - Open export sheet — preview renders correctly

---

## 8. File Manifest

| File | Action | Priority |
|------|--------|----------|
| `Engine/AlignmentEngine.swift` | Add `RotationSnapEngine` namespace | P0 |
| `ViewModels/CanvasViewModel.swift` | Add undo/redo stack, custom guides, rotation snap announcements | P0 |
| `Views/TextOverlayView.swift` | Double-tap, rotation snap, degree badge | P0 |
| `Views/ImageOverlayView.swift` | Double-tap, rotation snap, degree badge | P0 |
| `Services/HapticsService.swift` | Add `rotationSnap()` | P0 |
| `Views/CanvasView.swift` | Undo/redo buttons, toolbar auto-hide, selection bracket corners | P0/P2 |
| `Views/ColorPickerView.swift` | **New** — tabbed color picker with wheel + eyedropper | P1 |
| `Views/ColorWheelView.swift` | **New** — HSB conic gradient Canvas | P1 |
| `Views/ColorGrid.swift` | Integrate into ColorPickerView as "Palette" tab | P1 |
| `Views/StyleControlsView.swift` | Swap ColorGrid → ColorPickerView | P1 |
| `ViewModels/SettingsViewModel.swift` | Add `recentColors` persistence | P1 |
| `Views/GuidesOverlayView.swift` | Snap zone bands, custom guide rendering | P1 |
| `Views/CustomGuidesOverlay.swift` | **New** — ruler strips + guide drag interaction | P1 |
| `Views/ExportSheet.swift` | Preview image, re-render button, taller detent | P2 |
| `GlyphDesignSystem.swift` | Corner bracket selection helpers | P2 |
| `Tests/GlyphTests/RotationSnapEngineTests.swift` | **New** | P0 |
| `Tests/GlyphTests/UndoStackTests.swift` | **New** | P0 |
| `Tests/GlyphTests/CustomGuideTests.swift` | **New** | P1 |

---

## 9. Risks & Mitigations

| Risk | Likelihood | Mitigation |
|------|-----------|------------|
| Undo snapshots bloat memory (50 × full layer array) | Medium | Cap layer image data at 200×200 thumbnails in snapshots; don't store full UIImage |
| Color wheel Canvas redraws at 60fps during drag | Low | `.drawingGroup()` on the wheel view; same approach as GuidesOverlayView |
| Custom guide drag conflicts with layer drag | Medium | Custom guides only interactive when `showGuides == true`; separate hit-testing zone |
| ExportEngine preview render blocks main thread | Medium | Render on background task; show placeholder spinner while rendering |
| Shake-to-undo conflicts with system alert (undo/redo prompt) | Low | Use custom UIResponder chain, not UIKit's built-in undoManager UI |

---

## 10. Future Considerations (Out of Scope)

- **Gesture keyboard:** Two-finger tap = undo, three-finger tap = redo (Procreate-style)
- **Per-project custom guides:** Persisted to disk with layer data
- **Color picker: CMYK / HEX input** for print-export workflows
- **Loupe / zoom canvas:** Pinch on empty canvas to zoom in for precise positioning
- **Guide locking:** Lock custom guides so they can't be accidentally moved

---

*This spec was generated from a conversation with the user on 2026-04-06,
capturing their vision of a mobile-first design tool where "thumbs do
the thinking."*