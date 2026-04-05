# Glyph Design System Spec

**Date:** 2026-04-05
**Direction:** Light typographic — iA Writer clarity × Things depth × Heron Preston industrial edge
**Accent:** Electric green

---

## Design Principles

1. **Content is the interface** (iA Writer) — Typography does the heavy lifting. Zero chrome. Monospace labels for utility text. The canvas IS the app.
2. **Soft depth, not flat** (Things) — Floating sheets with shadows, not hard borders. Controls feel physical. Spatial hierarchy through elevation.
3. **Industrial confidence** (Heron Preston) — Electric green as signature mark. Uppercase monospace labels. High contrast. Utilitarian, not decorative.

---

## Color Tokens

| Token | Hex | Usage |
|---|---|---|
| `canvas` | `#FFFFFF` | Main background, editing canvas |
| `surface` | `#F7F7F7` | Cards, panels, secondary backgrounds |
| `surfaceAlt` | `#EBEBEB` | Pressed states, dividers, inset areas |
| `accent` | `#39FF14` | Primary action, selection, active state |
| `accentSubtle` | `#39FF14` @ 15% | Accent backgrounds, soft highlights |
| `textPrimary` | `#1A1A1A` | Headlines, body text, primary content |
| `textSecondary` | `#6B6B6B` | Captions, descriptions, metadata |
| `textTertiary` | `#B0B0B0` | Placeholders, disabled text |
| `border` | `#E0E0E0` | Dividers, input borders |
| `borderSubtle` | `#F0F0F0` | Soft separators |
| `shadow` | `#000000` @ varying alpha | Elevation (see Shadows) |
| `error` | `#FF3B30` | Error states |

### Dark Mode (deferred)

Not in scope for v1. Light-only. Token architecture supports future dark mode by swapping values.

---

## Typography Scale

| Token | Size | Weight | Tracking | Font |
|---|---|---|---|---|
| `display` | 28pt | Bold (700) | -0.5pt | System (SF Pro) |
| `title` | 20pt | Semibold (600) | -0.3pt | System (SF Pro) |
| `body` | 16pt | Regular (400) | 0 | System (SF Pro) |
| `caption` | 13pt | Regular (400) | 0 | System (SF Pro) |
| `label` | 11pt | Medium (500) | 1.5pt | Monospaced (SF Mono) |

### Label Convention (Heron Preston / iA Writer)

Utility labels use monospaced uppercase with wide tracking — `EXPORT`, `STYLE`, `FONT`. This is the industrial accent that distinguishes Glyph from generic iOS apps.

---

## Spacing Scale

| Token | Value |
|---|---|
| `xs` | 4pt |
| `sm` | 8pt |
| `md` | 12pt |
| `lg` | 16pt |
| `xl` | 24pt |
| `xxl` | 32pt |

---

## Corner Radius

| Token | Value | Usage |
|---|---|---|
| `sm` | 6pt | Small chips, tags |
| `md` | 10pt | Buttons, inputs |
| `lg` | 14pt | Cards, panels |
| `xl` | 20pt | Sheets, modals |
| `pill` | 999pt | Pill buttons, toggles |

---

## Shadows (Things-style depth)

| Token | Value | Usage |
|---|---|---|
| `soft` | 0 2px 8px rgba(0,0,0,0.06) | Cards, subtle elevation |
| `medium` | 0 4px 16px rgba(0,0,0,0.10) | Floating controls, active cards |
| `sheet` | 0 -4px 24px rgba(0,0,0,0.12) | Bottom sheets, modals |

---

## Component Design Rules

### Canvas (Main Screen)
- Pure white `canvas` background
- No visible toolbar chrome — actions float or live in minimal top bar
- iA Writer style: the text you're editing dominates the viewport

### Bottom Sheets (Style Controls, Font Picker, Export)
- Things-style floating sheets: `xl` radius top corners, `sheet` shadow
- `surface` background
- Grabber indicator: 36×4pt, `surfaceAlt`, `pill` radius
- Content padded `xl` from edges

### Buttons
- Primary: `accent` fill, `textPrimary` label (green on dark text for contrast)
- Secondary: `surface` fill, `border` stroke, `textPrimary` label
- Ghost: transparent, `textSecondary` label, no border
- All buttons: `md` radius, `lg` vertical padding, `xl` horizontal padding

### Selection & Active States
- Selected items: `accentSubtle` background tint
- Active controls: `accent` indicator (underline, dot, or ring)
- Haptic feedback on all interactive elements

### Labels & Headers
- Section labels: `label` token — 11pt monospaced, uppercase, wide tracking
- Sheet titles: `title` token — 20pt semibold
- No decorative elements — typography and spacing create hierarchy

---

## Architecture

### Token File: `GlyphDesignSystem.swift`
Single source of truth. All colors, typography, spacing, radius, and shadows as static properties on namespaced enums. No raw values anywhere else in codebase.

```
GlyphDesignSystem
├── Color      (canvas, surface, accent, text*, border*, error)
├── Typography (display, title, body, caption, label)
├── Spacing    (xs, sm, md, lg, xl, xxl)
├── Radius     (sm, md, lg, xl, pill)
└── Shadow     (soft, medium, sheet)
```

### Preview Catalog: `ComponentCatalog.swift`
SwiftUI Preview file that renders every token and component state. Acts as the "Storybook" — visual regression checking via Xcode previews.

### Migration from `GlyphTheme.swift`
Replace existing `GlyphTheme` enum with `GlyphDesignSystem`. Update all views to use new tokens. Delete `GlyphTheme.swift`.

---

## What This Spec Does NOT Cover

- Dark mode (deferred)
- Animation/motion design (separate spec if needed)
- App icon / branding
- Onboarding flows
