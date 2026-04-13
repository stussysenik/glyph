# Glyph Parametric Snap Engine — Design

**Date:** 2026-04-13
**Status:** Draft — awaiting user approval before build
**Scope:** `origami-playground` sketchbook + `glyph/ios-native` port path
**Author:** brainstorming session

---

## 1. Objective

Build a parametric, dependency-injected layer snap engine for designing
Instagram Stories (and arbitrary aspect ratios) where:

1. A user-selected **Foundation** gives the canvas its geometric structure —
   golden ratio first, extensible to thirds, halves, hex, polar.
2. Layers compose into a **scene graph** with one **root** ("founder,
   originator, absolute bottom"). Transforms cascade parent → child.
3. New layers **snap to the composite boundary** of everything already placed,
   plus the foundation's guides underneath. As you build, the grid gets
   richer — the composite *is* the grid.
4. Each layer exposes its own `SnapTargetProvider` strategy so the snap
   engine stays dumb — rectangles use bbox targets, circles will use path
   outline targets later, all through the same interface.
5. Rotation snaps to cardinals (0°/90°/180°/270°) reusing the existing
   `AlignmentEngine.swift:124-170` logic, ported 1:1 to JS.

The whole system lives in the `origami-playground` sketchbook first, as a
shared engine consumed by **three** prototype shells that each expose
different slices of the DI surface. Proven engine patches then port 1:1 into
a new `ParametricSnapEngine.swift` in Glyph's iOS target, coexisting with
the current `AlignmentEngine` until we're ready to replace it.

## 2. Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         UI SHELL                                │
│   (P1 feel  /  P2 parametric  /  P3 template)                   │
│   - mounts a Canvas, supplies Foundation + root Layer           │
│   - optionally exposes dropdowns/sliders bound to DI            │
└────────────────────────┬────────────────────────────────────────┘
                         │ composition root (DI wiring lives here)
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                    PARAMETRIC ENGINE                            │
│   Canvas          ← viewport + aspectRatio                      │
│     └─ SceneGraph ← tree with root = founder; transforms cascade│
│                                                                 │
│   Foundation (interface)                                        │
│     ├─ GoldenRatioFoundation  (v1 default)                      │
│     ├─ ThirdsFoundation                                         │
│     └─ HalvesFoundation                                         │
│                                                                 │
│   Layer                                                         │
│     - id, parentId, children, localTransform                    │
│     - SnapTargetProvider (interface, injected)                  │
│         └─ BBoxTargets  (v1 default)                            │
│                                                                 │
│   SnapResolver — parent → siblings → foundation priority        │
│   RotationCardinalSnap — pure fn, port of Swift                 │
└─────────────────────────────────────────────────────────────────┘
```

**Isolation contract:** every box has one job and one interface. `Canvas`
knows nothing about layers. `SceneGraph` knows nothing about snap.
`Foundation` knows nothing about layers. `Layer.SnapTargetProvider` knows
nothing about other layers. `SnapResolver` knows nothing about rendering.

## 3. Data flow on drag

```
FRAME 0 — pointerdown
  shell.hitTest(sceneGraph, px, py) → Layer?
  capture grab offset so layer doesn't recenter on finger

FRAMES 1..N — pointermove (~60fps)
  rawPos = fingerPos − grabOffset
  SnapResolver.resolve(rawPos, layer, sceneGraph, foundation, radius)
    1. parent.snapTargets()
    2. every non-ancestor sibling.snapTargets()
    3. foundation.snapTargets()
    → pick closest within radius → blend rawPos toward target
    → return { snappedPos, guides, strength 0..1 }
  layer.localTransform.pos ← snappedPos (magnet blend, not hard snap)
  sceneGraph.cascadeTransform(layer)
  render dragged layer at 0.75 opacity / 1.05 scale
  highlight guides, haptic at strength > 0.7

FRAME N+1 — pointerup
  if had guides → HARD LOCK to snappedPos
  else → leave at rawPos (free placement)
  sceneGraph.commit
```

**Decisions baked in:**

- **Magnet blend during drag, hard lock on release** — Procreate feel, not
  Figma binary click. Proven in `patches/element-drag.js:60-62`.
- **Priority enforced at target-collection time**, not resolution time.
- **Non-ancestor siblings only** — you can't snap to your own descendants or
  ancestors (ancestors move with you via transform cascade).
- **Haptic at `strength > 0.7`**, not per target cross — prevents spam.

## 4. Engine interfaces

```js
Canvas { aspectRatio, width, height }

SceneGraph {
  root: Layer
  walk(fn), getAncestors(l), getDescendants(l)
  addChild(parent, newLayer), cascadeTransform(l), commit()
}

Foundation {
  guides(canvas)      → [{ kind: 'line'|'point'|'arc', geometry, key }]
  snapTargets(canvas) → [{ kind: 'line'|'point', geometry, priority }]
}

Layer {
  id, parentId, children
  localTransform: { x, y, rotation, scale }
  snapTargetProvider: SnapTargetProvider
  render: { kind: 'text'|'image'|'shape', props }
}

SnapTargetProvider {
  snapTargets(layer, worldTransform) → [{ kind, geometry, ownerId }]
}

SnapResolver.resolve(rawPos, layer, sceneGraph, foundation, radius) → {
  snappedPos, guides: [TargetRef], strength: 0..1
}

RotationCardinalSnap.snap(angleDeg, threshold=5) → Number | null
```

## 5. Three prototype shells

| Shell | Canvas | Foundation | Start layers | DI exposed |
|---|---|---|---|---|
| **P1 `feel-snap`** | 9:16 hardcoded | GoldenRatio hardcoded | 3 pre-placed (root frame + 2 text) | none — just drag |
| **P2 `parametric-snap`** | dropdown: 9:16 / 1:1 / 4:5 | dropdown: golden / thirds / halves | 1 root + "add layer" toolbar | aspect + foundation live recompute |
| **P3 `template-snap`** | 9:16 | GoldenRatio | curated tree: root frame + title + subtitle + brand mark | none — user edits text/swaps images |

All three consume the **same engine patches** from the top-level `patches/`
directory. Shell differences live in each `sketch.json` + a thin shell JS.

## 6. Testing

- **Primary:** visual verification in the sketchbook runtime — drag layers,
  see guide highlights, feel composite surface emerging.
- **Secondary:** `patches/verify.mjs` pattern — pure-function unit tests on
  `snap-resolver.js`, `bbox-targets.js`, `foundation-golden.js`.
- **No Swift tests yet** — port happens after engine is visually proven.

## 7. File manifest

**New engine patches (shared, top-level):**

- `patches/scene-graph.js`
- `patches/foundation-golden.js`
- `patches/foundation-thirds.js`
- `patches/foundation-halves.js`
- `patches/bbox-targets.js`
- `patches/snap-resolver.js`
- `patches/rotation-cardinal.js`

**Three prototype folders:**

- `prototypes/feel-snap/` — `sketch.json`, `notes.md`, patches references
- `prototypes/parametric-snap/` — same
- `prototypes/template-snap/` — same

**Swift port target (future, not this session):**

- new file `glyph/ios-native/Glyph/Sources/Engine/ParametricSnapEngine.swift`
- coexists with existing `AlignmentEngine.swift:6-87` (no replacement yet)

## 8. Acceptance criteria

- [ ] All 3 prototypes load in the runtime and render their initial layer tree
- [ ] P1: drag a text layer, feel it snap to golden guides + other layers
- [ ] P1: rotate a layer, feel it click into 0°/90°/180°/270°
- [ ] P2: switch foundation dropdown (golden → thirds → halves), see targets live-update
- [ ] P2: switch aspect ratio dropdown, see canvas + foundation rescale
- [ ] P3: drop a layer into the curated template, watch it auto-parent to the nearest branch
- [ ] All 3 share the same engine patches — no duplication
- [ ] Snap math is pure functions; `patches/verify.mjs` tests pass

## 9. Out of scope for this session

- Swift port (deferred until JS engine is visually proven)
- ConvexHullTargets / PathUnionTargets (future `SnapTargetProvider`s)
- HexFoundation / PolarFoundation (future foundations)
- Undo/redo integration (belongs to HCI-002 separately)
- Re-parenting during drag (drop onto new parent)
- Multi-touch gestures beyond single-layer drag + rotation

## 10. Open questions (deferred, not blocking build)

1. **Who is the parent of a newly-dropped layer?** Auto-chain, auto-snap-target,
   always root, or manual? Deferred — for now: always the root in P1/P2,
   curated tree in P3.
2. **Haptic feel on the web:** no real haptic in browser; log + visual pulse
   instead, preserve haptic hook for Swift port.
3. **What does "free placement" look like** when rawPos is outside every
   target's radius? For v1: leave at rawPos, no snap. Reconsider after feel.

---

*Generated from a brainstorming conversation on 2026-04-13 with goal
"easy Instagram story designing" — parametric composition engine where the
composite boundary IS the grid.*
