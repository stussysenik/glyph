# PERF-001: Cold Start & Interaction Latency

**Status:** Proposed  
**Author:** Claude  
**Date:** 2026-04-05  
**Scope:** ios-native/Glyph — Performance optimization  

---

## 1. Objective

Eliminate all observable jank and reduce cold start time in the Glyph iOS app. The app currently blocks the main thread during startup (font registration), export (triple PNG rendering), and drag interactions (O(n²) snap calculations). These issues make the app feel sluggish on first launch and during core interactions.

**Target users:** Creators who expect 60fps responsiveness and sub-1-second launch (Instagram-grade UX).

**Success criteria:**
- Cold start to interactive canvas: < 500ms (currently blocked by synchronous font registration)
- Drag gesture frame budget: < 8ms per frame (currently unbounded due to AlignmentEngine + sortedLayers recomputation)
- Export time: render once, reuse across Instagram/Photos/Clipboard (currently renders 3x)
- Zero main-thread hangs > 100ms (measurable via Instruments Hangs template)

---

## 2. Root Cause Analysis

### P0 — Cold Start Hang

**File:** `FontLibraryViewModel.swift:12-14`  
**Problem:** `init()` calls `loadCustomFonts()` + `registerCustomFonts()` synchronously. `registerCustomFonts()` loops through all user-imported fonts calling `FontLoader.register(url:)` → `CTFontManagerRegisterFontsForURL()`, which is I/O-bound and blocks the main thread.

**Impact:** With 10+ imported fonts, app launch is visibly delayed. Bundled fonts are registered via Info.plist (handled by iOS before app code runs), so they're fine — but custom fonts block.

```swift
// Current — synchronous in init()
init() {
    fonts = FontEntry.bundled + loadCustomFonts()  // UserDefaults decode
    registerCustomFonts()                           // BLOCKS: file I/O + CoreText
}
```

### P0 — Triple Export Rendering

**File:** `ExportSheet.swift:104-107, 109-171`  
**Problem:** Each export action calls `renderImage()` independently, which calls `ExportEngine.renderLayers()` — a synchronous 1080×1920 `UIGraphicsImageRenderer` composite on the main thread. If user taps "Instagram" then "Save to Photos", the image is rendered twice. `copyToClipboard()` can render a third time.

**Impact:** Each render takes 50-200ms depending on layer count. Main thread is fully blocked during render.

```swift
// Current — renders fresh each time
private func renderImage() -> UIImage? {
    let canvasSize = CGSize(width: 1080, height: 1920)
    return ExportEngine.renderLayers(canvas.layers, background: canvas.background, canvasSize: canvasSize)
}
```

### P1 — Uncached sortedLayers

**File:** `CanvasViewModel.swift:281-283`  
**Problem:** `sortedLayers` is a computed property that sorts the entire `layers` array on every access. `CanvasView.swift:170` uses it in a `ForEach`, meaning it re-sorts on every view render — including every drag frame.

```swift
var sortedLayers: [any Layer] {
    layers.sorted { $0.zIndex < $1.zIndex }  // O(n log n) per frame
}
```

**Impact:** During drag, this is called 60x/sec. With 10+ layers, this adds measurable overhead to each frame.

### P1 — AlignmentEngine per-frame overhead

**File:** `AlignmentEngine.swift:6-87`, called from `CanvasViewModel.swift:179-201`  
**Problem:** `snapPosition()` is called on every drag event. It iterates all other visible layers (O(n)) with 6 snap targets each. For each target, it runs the snap check (constant). The total is O(6n) per drag frame, plus `otherLayerGeometries()` rebuilds the geometry array each call.

**Actual complexity:** O(n) per frame — not as bad as initially feared, but the allocation of `[LayerGeometry]` array + deduplication via Dictionary grouping on every frame is wasteful.

```swift
// Called 60x/sec during drag
func updatePosition(id: UUID, position: CGSize) {
    let layerSize = boundingSize(for: layer)       // allocation
    let others = otherLayerGeometries(excluding: id) // O(n) array build
    let (snapped, guides) = AlignmentEngine.snapPosition(...)  // O(6n) + dict dedup
    // ...
}
```

### P2 — Export on main thread

**File:** `ExportEngine.swift:8-46`  
**Problem:** `renderLayers()` is synchronous and runs on whatever thread calls it — which is always the main thread via `ExportSheet`. The `UIGraphicsImageRenderer.image {}` closure does all compositing synchronously.

### P2 — InstagramSharer fake async

**File:** `InstagramSharer.swift:35-43`  
**Problem:** `saveToPhotos()` wraps `UIImageWriteToSavedPhotosAlbum` in a continuation but uses a hardcoded 500ms `asyncAfter` delay instead of the completion handler. This blocks the continuation for 500ms unnecessarily.

```swift
DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
    continuation.resume(returning: true)
}
```

### P3 — GuidesOverlayView Path reconstruction

**File:** `GuidesOverlayView.swift:34-96`  
**Problem:** Grid paths (rule of thirds, golden ratio, even grid) are reconstructed on every render. These are static geometry that only depends on `canvasSize` and `gridType` — they should be cached.

---

## 3. Fix Plan

### Fix 1: Async font registration (P0 — Cold Start)

**File:** `FontLibraryViewModel.swift`

Move custom font registration to a background task. Bundled fonts are already registered by iOS via Info.plist.

```swift
init() {
    fonts = FontEntry.bundled + loadCustomFonts()
    // Don't block init — register async
    Task.detached(priority: .userInitiated) { [fonts] in
        for entry in fonts where !entry.isBundled {
            guard let path = entry.filePath else { continue }
            let url = URL(fileURLWithPath: path)
            if FileManager.default.fileExists(atPath: path) {
                _ = FontLoader.register(url: url)
            }
        }
    }
}
```

**Risk:** Font may not be registered when user opens font picker immediately after launch. Mitigation: bundled fonts are always available instantly. Custom fonts appear in the list (loaded from UserDefaults) but may briefly show in system font until registration completes. This is acceptable — registration takes < 100ms per font, so all fonts will be ready well before user can navigate to the picker.

### Fix 2: Cache rendered export image (P0 — Triple Render)

**File:** `ExportSheet.swift`

Render once when the sheet opens, cache the result, reuse for all export actions.

```swift
@State private var cachedExport: UIImage?

private func ensureRendered() -> UIImage? {
    if let cached = cachedExport { return cached }
    let image = renderImage()
    cachedExport = image
    return image
}
```

Use `ensureRendered()` in all three export paths. Invalidate on dismiss.

### Fix 3: Cache sortedLayers (P1)

**File:** `CanvasViewModel.swift`

Replace the computed property with a cached value that updates only when `layers` changes.

```swift
private var _sortedLayers: [any Layer] = []

var sortedLayers: [any Layer] { _sortedLayers }

private func invalidateSortCache() {
    _sortedLayers = layers.sorted { $0.zIndex < $1.zIndex }
}
```

Call `invalidateSortCache()` in `addTextLayer()`, `addImageLayer()`, `removeLayer()`, `moveLayer()`, `renumberZIndices()`, and `replaceLayer()` — the only places that mutate `layers`.

### Fix 4: Reduce AlignmentEngine per-frame allocations (P1)

**File:** `CanvasViewModel.swift` + `AlignmentEngine.swift`

1. Pre-allocate a reusable `[LayerGeometry]` buffer instead of rebuilding each frame
2. Replace Dictionary-based deduplication with a simple Set check

```swift
// In CanvasViewModel — reuse buffer
private var _otherGeometries: [LayerGeometry] = []

private func otherLayerGeometries(excluding id: UUID) -> [LayerGeometry] {
    _otherGeometries.removeAll(keepingCapacity: true)
    for layer in layers where layer.id != id && layer.isVisible {
        _otherGeometries.append(LayerGeometry(position: layer.position, size: boundingSize(for: layer)))
    }
    return _otherGeometries
}
```

### Fix 5: Move export rendering off main thread (P2)

**File:** `ExportSheet.swift`

Wrap the render call in `Task.detached` and update UI on completion.

```swift
private func renderImageAsync() async -> UIImage? {
    await Task.detached(priority: .userInitiated) {
        let canvasSize = CGSize(width: 1080, height: 1920)
        return ExportEngine.renderLayers(canvas.layers, background: canvas.background, canvasSize: canvasSize)
    }.value
}
```

**Note:** `ExportEngine.renderLayers` uses UIKit rendering which needs `@MainActor` in some configurations. If we hit thread-safety issues, we fall back to keeping it on main thread but caching (Fix 2 already handles the main perf win).

### Fix 6: Fix InstagramSharer fake delay (P2)

**File:** `InstagramSharer.swift:34-43`

Use the proper completion selector pattern instead of a hardcoded 500ms delay.

```swift
static func saveToPhotos(_ image: UIImage) async -> Bool {
    await withCheckedContinuation { continuation in
        let saver = PhotoSaver(continuation: continuation)
        UIImageWriteToSavedPhotosAlbum(image, saver, #selector(PhotoSaver.didFinish), nil)
        // saver is retained by the runtime until the callback fires
    }
}

private class PhotoSaver: NSObject {
    let continuation: CheckedContinuation<Bool, Never>
    init(continuation: CheckedContinuation<Bool, Never>) { self.continuation = continuation }
    @objc func didFinish(_ image: UIImage, error: Error?, context: UnsafeMutableRawPointer?) {
        continuation.resume(returning: error == nil)
    }
}
```

### Fix 7: Cache grid paths (P3)

**File:** `GuidesOverlayView.swift`

This is low priority — SwiftUI Canvas already has some internal optimization. The grid geometry only depends on `canvasSize`, `gridType`, and `gridColumns`. If we observe jank during grid display, extract the path computation into a cached helper keyed on those three values.

---

## 4. Implementation Order

| # | Fix | Priority | Risk | Est. LOC |
|---|-----|----------|------|----------|
| 1 | Async font registration | P0 | Low | ~10 |
| 2 | Cache export image | P0 | Low | ~15 |
| 3 | Cache sortedLayers | P1 | Low | ~20 |
| 4 | Reduce alignment allocations | P1 | Low | ~15 |
| 5 | Off-main-thread export | P2 | Medium (UIKit threading) | ~20 |
| 6 | Fix saveToPhotos delay | P2 | Low | ~20 |
| 7 | Cache grid paths | P3 | Low | ~10 |

**Total estimated change:** ~110 LOC across 5 files.

---

## 5. Verification Plan

### Before (baseline measurements)
- [ ] Time Profiler: measure cold start to `CanvasView.onAppear` with 10 custom fonts imported
- [ ] Hangs instrument: record 30s of drag interaction with 5+ layers, count hangs > 16ms
- [ ] Manual: time export flow (tap Instagram → Instagram opens)

### After (pass criteria)
- [ ] Cold start: < 500ms to interactive (vs. baseline)
- [ ] Drag interaction: zero hangs > 16ms in 30s recording
- [ ] Export: single render call in Time Profiler trace (no duplicate `renderLayers` calls)
- [ ] `saveToPhotos` completes in actual save time (not hardcoded 500ms)
- [ ] All 36 existing unit tests pass
- [ ] Maestro E2E flows pass (add text + layer management)

### Regression checks
- [ ] Custom fonts render correctly after async registration
- [ ] Export PNG alpha channel preserved (transparent background)
- [ ] Instagram share still works end-to-end
- [ ] Layer ordering unchanged after sortedLayers caching

---

## 6. Boundaries

### Always do
- Measure before and after with Instruments
- Keep all fixes backward-compatible (no model changes)
- Run existing test suite after each fix

### Ask first
- Moving UIKit rendering off main thread (Fix 5) — may need `@MainActor` annotation
- Any changes to the AlignmentEngine algorithm (only reducing allocations, not changing snap behavior)

### Never do
- Change snap/alignment behavior (only optimize allocation patterns)
- Add new dependencies
- Modify the layer data model
- Touch UI layout or visual appearance
- Remove any existing functionality
