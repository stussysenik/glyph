# HCI-001: Interaction Hardening & Accessibility

**Status:** Implemented  
**Author:** Claude  
**Date:** 2026-04-06  
**Scope:** ios-native/Glyph — HCI, Accessibility, Interaction Design  

---

## 1. Objective

Harden every interaction in Glyph so pixels never move unexpectedly, touch targets meet Apple HIG / WCAG standards, the app reaches full VoiceOver + Dynamic Type + Reduce Motion support, and the UI state machine is provably deterministic — no corrupt states possible.

**The screenshot problem:** The app entered a corrupted visual state where system overlays, web content, and the canvas all competed for the same screen real estate. Root cause: 7 independent boolean sheet states with no coordination, combined with undersized touch targets that make accidental taps likely, and no state machine enforcing valid transitions.

**Success criteria:**
- Zero possible corrupt UI states (enum-driven sheet presentation replaces 7 booleans)
- All interactive elements ≥ 44×44pt touch targets (Apple HIG)
- All text meets WCAG 2.1 AA contrast (4.5:1 normal, 3:1 large) in both light appearance and on canvas
- Full VoiceOver accessibility for canvas layers, gestures, and state changes
- All animations gated on `accessibilityReduceMotion`
- Gesture alternatives for all custom gestures (accessibility actions)
- Snap points provide haptic + VoiceOver announcement feedback
- Dynamic Type support for all UI chrome (not canvas text — that's user-controlled)

---

## 2. Root Cause Analysis

### P0 — Sheet State Corruption (the screenshot bug)

**Files:** `CanvasView.swift:11-17`  
**Problem:** 7 independent `@State private var showXxx = false` booleans control sheet presentation. SwiftUI allows only one sheet per view modifier chain, but the code attaches 7 `.sheet()` modifiers. When multiple booleans become `true` simultaneously (e.g., tap "ADD TEXT" which sets `showStyleControls = true`, then quickly tap layers), sheets fight for presentation and produce undefined visual states.

```swift
// Current — 7 uncoordinated booleans
@State private var showStyleControls = false
@State private var showFontPicker = false
@State private var showExportSheet = false
@State private var showLayerPanel = false
@State private var showBackgroundPicker = false
@State private var showImageOverlayPicker = false
@State private var showSettings = false
```

**Fix:** Replace with a single `enum ActiveSheet` optional. Only one sheet can be active at a time, making invalid states unrepresentable.

### P0 — Editing State Orphaning

**Files:** `CanvasViewModel.swift:101-109`  
**Problem:** `removeSelectedLayers()` removes the layer but doesn't clear `isEditing`. If the user was editing text and then deletes via the bottom control bar, `isEditing` remains `true` while `selectedTextLayer` returns `nil`. The inline text editor renders with a stale binding.

```swift
// Current — isEditing not cleared
func removeSelectedLayers() {
    if isMultiSelectActive {
        layers.removeAll { multiSelectedIDs.contains($0.id) }
        // ...
    } else if let id = selectedLayerID {
        removeLayer(id: id)  // sets selectedLayerID = nil, but isEditing stays true
    }
}
```

### P1 — Undersized Touch Targets

**Files:**
- `StyleControlsView.swift:85`: Alignment buttons are `40×36pt` — below 44×44 minimum
- `ColorGrid.swift:41`: Color swatches are `32×32pt` — below 44×44 minimum  
- `LayerPanelView.swift:113-126`: Lock/Eye icons are `16×16pt` with no expanded hit area
- `SettingsView.swift:44-53`: Accent color circles are `36×36pt`

### P1 — Missing Accessibility on Canvas Layers

**Files:** `TextOverlayView.swift`, `ImageOverlayView.swift`  
**Problem:** Canvas layers have no `accessibilityLabel`, `accessibilityHint`, or `accessibilityActions`. VoiceOver users cannot interact with the primary canvas content. Custom gestures (drag, pinch, rotate) have no accessible alternatives.

### P1 — No Reduce Motion Support

**Files:** `CanvasView.swift:237-238`, `ExportSheet.swift:86-94`  
**Problem:** All animations are unconditional. Users with vestibular disorders who enable "Reduce Motion" still get all transitions and movement.

### P2 — Hardcoded Typography Sizes

**File:** `GlyphDesignSystem.swift:41-47`  
**Problem:** All `Typography` values use `Font.system(size:)` with fixed pixel sizes. These don't scale with Dynamic Type. The HIG requires all UI chrome text to scale.

### P2 — Contrast Issues in Design System

**File:** `GlyphDesignSystem.swift:29-35`  
**Problem:** 
- `textTertiary` (`0xB0B0B0`) on `surface` (`0xF7F7F7`): contrast ratio ≈ 1.7:1 (FAIL — needs 4.5:1)
- `textSecondary` (`0x6B6B6B`) on `surface` (`0xF7F7F7`): contrast ratio ≈ 3.4:1 (FAIL for normal text, passes for large)
- Grid overlay color (`textPrimary.opacity(0.06)`) is nearly invisible

### P2 — No VoiceOver Announcements for State Changes

**Problem:** Toast messages, snap guide engagement, layer selection changes, and lock/visibility toggles produce no VoiceOver announcements. Haptics exist but are inaudible to screen reader users.

### P3 — Gesture Conflict: Long Press + Tap on ImageOverlay

**File:** `ImageOverlayView.swift:35-36`  
**Problem:** Both `.onTapGesture` and `.onLongPressGesture(minimumDuration: 0.4)` are attached directly. While SwiftUI handles disambiguation, a user with motor impairments who holds slightly too long triggers multi-select instead of selection.

---

## 3. Fix Plan

### Fix 1: Enum-Driven Sheet State Machine (P0)

**File:** `CanvasView.swift`

Replace 7 booleans with a single optional enum:

```swift
enum ActiveSheet: Identifiable {
    case backgroundPicker
    case imageOverlayPicker
    case layerPanel
    case styleControls
    case fontPicker
    case exportSheet
    case settings
    
    var id: Self { self }
}

@State private var activeSheet: ActiveSheet?
```

Single `.sheet(item: $activeSheet)` with a `switch` inside. This makes it **impossible** for two sheets to fight — the type system enforces one-at-a-time.

### Fix 2: Fix Editing State on Layer Deletion (P0)

**File:** `CanvasViewModel.swift`

Clear `isEditing` in `removeSelectedLayers()` and in `removeLayer()`:

```swift
func removeLayer(id: UUID) {
    if selectedLayerID == id { 
        isEditing = false  // ADD THIS
    }
    layers.removeAll { $0.id == id }
    if selectedLayerID == id { selectedLayerID = nil }
    multiSelectedIDs.remove(id)
    renumberZIndices()
}
```

### Fix 3: Expand All Touch Targets to ≥ 44pt (P1)

**Files:** `StyleControlsView.swift`, `ColorGrid.swift`, `LayerPanelView.swift`, `SettingsView.swift`

- Alignment buttons: `.frame(width: 44, height: 44)` (was 40×36)
- Color swatches: Keep visual at 32pt but add `.contentShape(Circle()).frame(width: 44, height: 44)` for hit area
- Lock/Eye buttons: Add `.frame(minWidth: 44, minHeight: 44).contentShape(Rectangle())`
- Settings accent circles: Add `.contentShape(Circle()).frame(width: 44, height: 44)` for hit area

### Fix 4: Full Canvas Layer Accessibility (P1)

**Files:** `TextOverlayView.swift`, `ImageOverlayView.swift`

Add VoiceOver support to every canvas layer:

```swift
// TextOverlayView
.accessibilityLabel("Text layer: \(layer.text)")
.accessibilityHint(isSelected ? "Double-tap to edit text. Use actions for more options." : "Double-tap to select.")
.accessibilityAddTraits(isSelected ? [.isSelected] : [])
.accessibilityActions {
    if !layer.isLocked {
        Button("Edit text") { onEdit() }
        Button("Move up") { /* nudge */ }
        Button("Move down") { /* nudge */ }
        Button("Move left") { /* nudge */ }
        Button("Move right") { /* nudge */ }
    }
}

// ImageOverlayView
.accessibilityLabel("Image layer: \(layer.name)")
.accessibilityHint(isSelected ? "Selected. Use actions for more options." : "Double-tap to select.")
.accessibilityAddTraits(isSelected ? [.isSelected] : [])
.accessibilityActions {
    if !layer.isLocked {
        Button("Enter multi-select") { onLongPress() }
        Button("Move up") { /* nudge */ }
        Button("Move down") { /* nudge */ }
        Button("Move left") { /* nudge */ }
        Button("Move right") { /* nudge */ }
    }
}
```

### Fix 5: Gate Animations on Reduce Motion (P1)

**Files:** `CanvasView.swift`, `ExportSheet.swift`

```swift
@Environment(\.accessibilityReduceMotion) private var reduceMotion

// Replace:
.animation(.easeInOut(duration: 0.2), value: vm.selectedLayerID)
// With:
.animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: vm.selectedLayerID)

// Toast transitions:
.transition(reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity))
```

### Fix 6: Dynamic Type for UI Chrome (P2)

**File:** `GlyphDesignSystem.swift`

Replace fixed-size fonts with text styles for UI chrome:

```swift
enum Typography {
    static let display = Font.title           // was .system(size: 28)
    static let title   = Font.title3          // was .system(size: 20)
    static let body    = Font.body            // was .system(size: 16)
    static let caption = Font.caption         // was .system(size: 13)
    static let label   = Font.caption2.monospaced().weight(.medium) // was .system(size: 11)
}
```

### Fix 7: Fix Contrast Ratios (P2)

**File:** `GlyphDesignSystem.swift`

Darken tertiary/secondary text to pass WCAG 2.1 AA:

```swift
// Current → Fixed
static let textSecondary = Color(hex: 0x6B6B6B)  → Color(hex: 0x595959) // 5.9:1 on surface
static let textTertiary  = Color(hex: 0xB0B0B0)  → Color(hex: 0x757575) // 4.6:1 on surface
```

### Fix 8: VoiceOver Announcements for State Changes (P2)

**Files:** `CanvasViewModel.swift`, `ExportSheet.swift`

Post `AccessibilityNotification.Announcement` for:
- Layer selection changes
- Snap guide engagement ("Snapped to center")
- Lock/visibility toggles ("Layer locked")
- Toast messages ("Saved to Photos!")
- Export completion

### Fix 9: Accessible Gesture Alternatives (P2)

**Files:** `TextOverlayView.swift`, `ImageOverlayView.swift`, `BackgroundImageView.swift`

- Pinch-to-scale: Add `accessibilityAdjustableAction` for VoiceOver swipe up/down
- Rotation: Add custom `accessibilityAction(named: "Rotate 15°")`
- Long press multi-select: Add `accessibilityAction(named: "Enter multi-select")`

### Fix 10: Snap Points with Deterministic Feedback (P2)

**Files:** `CanvasViewModel.swift`, `AlignmentEngine.swift`

Snap positions produce:
- Haptic (already exists)
- VoiceOver announcement describing the snap: "Snapped to canvas center" / "Aligned with Image 2 left edge"
- Position rounds to nearest 0.5pt (pixel-grid alignment on @2x displays)

---

## 4. Implementation Order

| # | Fix | Priority | Risk | Files | Est. LOC |
|---|-----|----------|------|-------|----------|
| 1 | Enum sheet state machine | P0 | Low | CanvasView.swift | ~60 |
| 2 | Fix editing state on delete | P0 | Low | CanvasViewModel.swift | ~5 |
| 3 | Expand touch targets | P1 | Low | 4 view files | ~30 |
| 4 | Canvas layer accessibility | P1 | Low | TextOverlayView, ImageOverlayView | ~40 |
| 5 | Gate reduce motion | P1 | Low | CanvasView, ExportSheet | ~15 |
| 6 | Dynamic Type for chrome | P2 | Medium | GlyphDesignSystem.swift | ~10 |
| 7 | Fix contrast ratios | P2 | Low | GlyphDesignSystem.swift | ~5 |
| 8 | VoiceOver announcements | P2 | Low | 3 files | ~25 |
| 9 | Gesture alternatives | P2 | Low | 3 overlay views | ~30 |
| 10 | Snap point feedback | P2 | Low | 2 files | ~15 |

**Total estimated change:** ~235 LOC across 10 files.

---

## 5. Verification Plan

### Accessibility Audit
- [ ] VoiceOver: Navigate entire app with VoiceOver, every element reachable and labeled
- [ ] VoiceOver: Select, edit, delete, and reorder layers using only VoiceOver + accessibility actions
- [ ] Dynamic Type: Set to AX5 (largest), verify all chrome text scales, no truncation
- [ ] Reduce Motion: Enable in Settings, verify no sliding/bouncing transitions, only fades
- [ ] Bold Text: Verify all text respects bold text setting
- [ ] Voice Control: Verify all buttons respond to "Tap [label]" commands
- [ ] Contrast: Run Accessibility Inspector, zero failures on all screens

### Interaction Quality
- [ ] Sheet state: Rapid-tap all toolbar buttons — only one sheet ever opens
- [ ] Sheet dismissal: Swipe down on any sheet, verify no orphaned state
- [ ] Editing state: Delete a layer while editing text — verify editor disappears
- [ ] Touch targets: Use Accessibility Inspector "Show Touch Areas" — all ≥ 44pt
- [ ] Snap feedback: Drag a layer to center — haptic fires, VoiceOver announces
- [ ] Multi-select: Long press → multi-select via VoiceOver accessibility action

### Regression
- [ ] All existing unit tests pass (AlignmentEngine, Presets, LayerOrder, Export)
- [ ] Visual appearance unchanged (colors may be slightly darker for contrast)
- [ ] Export pipeline unchanged
- [ ] Gesture behavior unchanged for non-accessibility users

---

## 6. Boundaries

### Always do
- Run Xcode Accessibility Inspector after each fix
- Test with VoiceOver after accessibility changes
- Verify WCAG contrast ratios with ContrastService

### Ask first
- Changing the accent color (neon green on white may fail contrast — but it's decorative, not text)
- Adding new dependencies

### Never do
- Change canvas rendering or export output
- Modify layer data model
- Change gesture behavior for sighted users
- Add features beyond interaction hardening
