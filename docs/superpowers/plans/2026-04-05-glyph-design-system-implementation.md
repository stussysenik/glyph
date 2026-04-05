# Glyph Design System Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the dark `GlyphTheme` with a light typographic design system (iA Writer × Things × Heron Preston) using electric green accent, proper token architecture, and a SwiftUI preview catalog.

**Architecture:** Single `GlyphDesignSystem.swift` file defines all tokens (colors, typography, spacing, radius, shadows) as namespaced static properties. All 8 view files migrate from `GlyphTheme.*` to `GlyphDesignSystem.*`. A `ComponentCatalog.swift` preview file renders every token and component state for visual regression checking.

**Tech Stack:** SwiftUI, @Observable (iOS 17+), SF Pro + SF Mono system fonts, xcodegen

---

## File Map

| Action | File | Responsibility |
|--------|------|---------------|
| Create | `Sources/GlyphDesignSystem.swift` | All design tokens — colors, typography, spacing, radius, shadows |
| Create | `Sources/Views/ComponentCatalog.swift` | SwiftUI Preview catalog — visual Storybook |
| Modify | `Sources/GlyphApp.swift:14` | Remove `.preferredColorScheme(.dark)`, switch to light |
| Modify | `Sources/Views/CanvasView.swift` | Replace all `GlyphTheme.*` with `GlyphDesignSystem.*` |
| Modify | `Sources/Views/TextOverlayView.swift:29` | Replace `GlyphTheme.accent` selection border |
| Modify | `Sources/Views/StyleControlsView.swift` | Replace all `GlyphTheme.*` references |
| Modify | `Sources/Views/ColorGrid.swift:38` | Replace `GlyphTheme.accent` selection ring |
| Modify | `Sources/Views/FontPickerSheet.swift` | Replace all `GlyphTheme.*`, fix text colors for light bg |
| Modify | `Sources/Views/ExportSheet.swift` | Replace all `GlyphTheme.*`, fix text colors for light bg |
| Delete | `Sources/GlyphTheme.swift` | Old dark theme — fully replaced |

---

### Task 1: Create GlyphDesignSystem.swift — Token Foundation

**Files:**
- Create: `Sources/GlyphDesignSystem.swift`

- [ ] **Step 1: Create the design token file**

```swift
import SwiftUI

/// Glyph's design system — light typographic theme.
/// iA Writer clarity × Things depth × Heron Preston industrial edge.
///
/// This is the single source of truth for all visual tokens.
/// No raw color/font/spacing values anywhere else in the codebase.
enum GlyphDesignSystem {

    // MARK: - Color

    enum Color {
        static let canvas       = SwiftUI.Color(hex: 0xFFFFFF)
        static let surface      = SwiftUI.Color(hex: 0xF7F7F7)
        static let surfaceAlt   = SwiftUI.Color(hex: 0xEBEBEB)
        static let accent       = SwiftUI.Color(hex: 0x39FF14)
        static let accentSubtle = SwiftUI.Color(hex: 0x39FF14).opacity(0.15)
        static let textPrimary  = SwiftUI.Color(hex: 0x1A1A1A)
        static let textSecondary = SwiftUI.Color(hex: 0x6B6B6B)
        static let textTertiary = SwiftUI.Color(hex: 0xB0B0B0)
        static let border       = SwiftUI.Color(hex: 0xE0E0E0)
        static let borderSubtle = SwiftUI.Color(hex: 0xF0F0F0)
        static let error        = SwiftUI.Color(hex: 0xFF3B30)
        static let success      = SwiftUI.Color(hex: 0x34C759)
    }

    // MARK: - Typography

    enum Typography {
        static let display = Font.system(size: 28, weight: .bold)
        static let title   = Font.system(size: 20, weight: .semibold)
        static let body    = Font.system(size: 16, weight: .regular)
        static let caption = Font.system(size: 13, weight: .regular)
        /// Monospaced uppercase label — the Heron Preston / iA Writer signature.
        static let label   = Font.system(size: 11, weight: .medium, design: .monospaced)
    }

    // MARK: - Spacing

    enum Spacing {
        static let xs:  CGFloat = 4
        static let sm:  CGFloat = 8
        static let md:  CGFloat = 12
        static let lg:  CGFloat = 16
        static let xl:  CGFloat = 24
        static let xxl: CGFloat = 32
    }

    // MARK: - Radius

    enum Radius {
        static let sm:   CGFloat = 6
        static let md:   CGFloat = 10
        static let lg:   CGFloat = 14
        static let xl:   CGFloat = 20
        static let pill: CGFloat = 999
    }

    // MARK: - Shadow

    enum Shadow {
        static func soft(_ content: some View) -> some View {
            content.shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
        }
        static func medium(_ content: some View) -> some View {
            content.shadow(color: .black.opacity(0.10), radius: 8, x: 0, y: 4)
        }
        static func sheet(_ content: some View) -> some View {
            content.shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: -4)
        }
    }
}

// MARK: - Color Hex Initializer

extension Color {
    init(hex: UInt, opacity: Double = 1.0) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}
```

- [ ] **Step 2: Build to verify it compiles**

Run: `flowdeck build --project ios-native/Glyph/Glyph.xcodeproj --scheme Glyph`
Expected: Build succeeds (new file compiles alongside old GlyphTheme — no conflicts yet)

- [ ] **Step 3: Commit**

```bash
git add ios-native/Glyph/Sources/GlyphDesignSystem.swift
git commit -m "feat: add GlyphDesignSystem token foundation

Light typographic tokens: colors, typography, spacing, radius, shadows.
Single source of truth — replaces GlyphTheme in subsequent commits."
```

---

### Task 2: Migrate GlyphApp.swift — Switch to Light Mode

**Files:**
- Modify: `Sources/GlyphApp.swift:14`

- [ ] **Step 1: Remove dark color scheme preference**

Replace the entire body of `GlyphApp`:

```swift
var body: some Scene {
    WindowGroup {
        CanvasView()
            .environment(canvasVM)
            .environment(fontLibraryVM)
    }
}
```

Remove `.preferredColorScheme(.dark)` — the app now follows the system default (light).

- [ ] **Step 2: Build to verify**

Run: `flowdeck build --project ios-native/Glyph/Glyph.xcodeproj --scheme Glyph`
Expected: Build succeeds

- [ ] **Step 3: Commit**

```bash
git add ios-native/Glyph/Sources/GlyphApp.swift
git commit -m "feat: remove forced dark mode — app now uses light theme"
```

---

### Task 3: Migrate CanvasView.swift — Main Screen

**Files:**
- Modify: `Sources/Views/CanvasView.swift`

This is the biggest migration — the main screen uses `GlyphTheme` extensively.

- [ ] **Step 1: Replace all GlyphTheme references in CanvasView**

Full replacement of `CanvasView.swift`:

```swift
import SwiftUI

private typealias DS = GlyphDesignSystem

/// The main (and only) screen — light canvas with text overlays and controls.
struct CanvasView: View {
    @Environment(CanvasViewModel.self) private var canvas
    @Environment(FontLibraryViewModel.self) private var fontLibrary

    @State private var showStyleControls = false
    @State private var showFontPicker = false
    @State private var showExportSheet = false

    var body: some View {
        ZStack {
            // Background — tap to deselect
            DS.Color.canvas
                .ignoresSafeArea()
                .onTapGesture {
                    canvas.deselectAll()
                    showStyleControls = false
                }

            // Overlays
            ForEach(canvas.overlays) { overlay in
                TextOverlayView(
                    overlay: overlay,
                    isSelected: canvas.selectedOverlayID == overlay.id
                )
            }

            // Top toolbar
            VStack {
                HStack {
                    Button {
                        let font = fontLibrary.fonts.first?.familyName ?? "Playfair Display"
                        canvas.addOverlay(fontFamily: font)
                        showStyleControls = true
                    } label: {
                        Text("ADD TEXT")
                            .font(DS.Typography.label)
                            .tracking(1.5)
                            .foregroundStyle(DS.Color.accent)
                    }

                    Spacer()

                    if !canvas.overlays.isEmpty {
                        Button {
                            showExportSheet = true
                        } label: {
                            Text("EXPORT")
                                .font(DS.Typography.label)
                                .tracking(1.5)
                                .foregroundStyle(DS.Color.accent)
                        }
                    }
                }
                .padding(.horizontal, DS.Spacing.xl)
                .padding(.top, DS.Spacing.sm)

                Spacer()

                // Bottom controls for selected overlay
                if canvas.selectedOverlay != nil {
                    HStack(spacing: DS.Spacing.lg) {
                        controlButton(icon: "textformat") {
                            showFontPicker = true
                        }

                        controlButton(icon: "slider.horizontal.3") {
                            showStyleControls = true
                        }

                        controlButton(icon: "trash", tint: DS.Color.error) {
                            canvas.removeSelected()
                            showStyleControls = false
                        }
                    }
                    .padding(.bottom, DS.Spacing.xl)
                }
            }

            // Inline text editor when editing
            if canvas.isEditing, let overlay = canvas.selectedOverlay {
                VStack {
                    Spacer()
                    TextField("Type something", text: Binding(
                        get: { overlay.text },
                        set: { canvas.updateText($0) }
                    ))
                    .font(DS.Typography.title)
                    .foregroundStyle(DS.Color.textPrimary)
                    .padding(DS.Spacing.lg)
                    .background(DS.Color.surface)
                    .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md))
                    .padding(.horizontal, DS.Spacing.xl)
                    .padding(.bottom, 80)
                }
                .transition(.move(edge: .bottom))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: canvas.selectedOverlayID)
        .animation(.easeInOut(duration: 0.2), value: canvas.isEditing)
        .sheet(isPresented: $showStyleControls) {
            if canvas.selectedOverlay != nil {
                StyleControlsView()
                    .environment(canvas)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
                    .presentationBackground(DS.Color.surface)
            }
        }
        .sheet(isPresented: $showFontPicker) {
            FontPickerSheet()
                .environment(canvas)
                .environment(fontLibrary)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationBackground(DS.Color.surface)
        }
        .sheet(isPresented: $showExportSheet) {
            ExportSheet()
                .environment(canvas)
                .presentationDetents([.height(280)])
                .presentationDragIndicator(.visible)
                .presentationBackground(DS.Color.surface)
        }
    }

    /// Bottom control button — Things-style floating circle with soft shadow.
    private func controlButton(
        icon: String,
        tint: SwiftUI.Color = DS.Color.textPrimary,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(tint)
                .frame(width: 44, height: 44)
                .background(DS.Color.canvas, in: Circle())
                .shadow(color: .black.opacity(0.10), radius: 8, x: 0, y: 4)
        }
    }
}
```

Key changes from old version:
- Toolbar labels: SF Symbol icons → uppercase monospace text labels (`ADD TEXT`, `EXPORT`) — iA Writer/Heron Preston style
- Bottom control circles: dark `surface` bg → white `canvas` bg with Things-style `medium` shadow
- All colors: `GlyphTheme.*` → `DS.Color.*`
- All spacing: magic numbers → `DS.Spacing.*`
- Text field: white text on dark → dark text on light surface
- Removed `editingText` state var (was unused)

- [ ] **Step 2: Build to verify**

Run: `flowdeck build --project ios-native/Glyph/Glyph.xcodeproj --scheme Glyph`
Expected: Build succeeds

- [ ] **Step 3: Commit**

```bash
git add ios-native/Glyph/Sources/Views/CanvasView.swift
git commit -m "feat: migrate CanvasView to GlyphDesignSystem

Light canvas, monospace toolbar labels, Things-style floating controls."
```

---

### Task 4: Migrate TextOverlayView.swift

**Files:**
- Modify: `Sources/Views/TextOverlayView.swift:29`

- [ ] **Step 1: Replace GlyphTheme.accent with DS.Color.accent**

Change line 29 from:
```swift
.stroke(GlyphTheme.accent, lineWidth: 1.5)
```
to:
```swift
.stroke(DS.Color.accent, lineWidth: 1.5)
```

Add the typealias at the top of the file, after `import SwiftUI`:
```swift
private typealias DS = GlyphDesignSystem
```

Also update the default `textColor` for new overlays — currently `.white` which won't show on a white canvas. In `TextOverlay.swift`, change the default:
```swift
textColor: Color = .black,
```

- [ ] **Step 2: Build to verify**

Run: `flowdeck build --project ios-native/Glyph/Glyph.xcodeproj --scheme Glyph`
Expected: Build succeeds

- [ ] **Step 3: Commit**

```bash
git add ios-native/Glyph/Sources/Views/TextOverlayView.swift ios-native/Glyph/Sources/Models/TextOverlay.swift
git commit -m "feat: migrate TextOverlayView + default text color to black for light canvas"
```

---

### Task 5: Migrate StyleControlsView.swift

**Files:**
- Modify: `Sources/Views/StyleControlsView.swift`

- [ ] **Step 1: Replace all GlyphTheme references**

Full replacement of `StyleControlsView.swift`:

```swift
import SwiftUI

private typealias DS = GlyphDesignSystem

/// Bottom sheet with styling controls for the selected overlay.
struct StyleControlsView: View {
    @Environment(CanvasViewModel.self) private var canvas

    var body: some View {
        if let overlay = canvas.selectedOverlay {
            VStack(spacing: DS.Spacing.xl) {
                // Font Size
                VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                    HStack {
                        Text("SIZE")
                            .font(DS.Typography.label)
                            .tracking(1.5)
                            .foregroundStyle(DS.Color.textTertiary)
                        Spacer()
                        Text("\(Int(overlay.fontSize))pt")
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(DS.Color.textSecondary)
                    }
                    Slider(
                        value: Binding(
                            get: { overlay.fontSize },
                            set: { canvas.updateFontSize($0) }
                        ),
                        in: 24...200,
                        step: 1
                    )
                    .tint(DS.Color.accent)
                }

                // Letter Spacing
                VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                    HStack {
                        Text("SPACING")
                            .font(DS.Typography.label)
                            .tracking(1.5)
                            .foregroundStyle(DS.Color.textTertiary)
                        Spacer()
                        Text(String(format: "%.1f", overlay.letterSpacing))
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(DS.Color.textSecondary)
                    }
                    Slider(
                        value: Binding(
                            get: { overlay.letterSpacing },
                            set: { canvas.updateLetterSpacing($0) }
                        ),
                        in: -5...20,
                        step: 0.5
                    )
                    .tint(DS.Color.accent)
                }

                // Alignment
                HStack(spacing: DS.Spacing.md) {
                    Text("ALIGN")
                        .font(DS.Typography.label)
                        .tracking(1.5)
                        .foregroundStyle(DS.Color.textTertiary)
                    Spacer()
                    ForEach(
                        [(TextAlignment.leading, "text.alignleft"),
                         (.center, "text.aligncenter"),
                         (.trailing, "text.alignright")],
                        id: \.0.hashValue
                    ) { alignment, icon in
                        Button {
                            canvas.updateAlignment(alignment)
                            UISelectionFeedbackGenerator().selectionChanged()
                        } label: {
                            Image(systemName: icon)
                                .font(.body)
                                .foregroundStyle(
                                    overlay.alignment == alignment
                                        ? DS.Color.accent
                                        : DS.Color.textSecondary
                                )
                                .frame(width: 40, height: 36)
                                .background(
                                    overlay.alignment == alignment
                                        ? DS.Color.accent.opacity(0.15)
                                        : SwiftUI.Color.clear,
                                    in: RoundedRectangle(cornerRadius: DS.Radius.sm)
                                )
                        }
                    }
                }

                // Color Grid
                VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                    Text("COLOR")
                        .font(DS.Typography.label)
                        .tracking(1.5)
                        .foregroundStyle(DS.Color.textTertiary)
                    ColorGrid(
                        selectedColor: Binding(
                            get: { overlay.textColor },
                            set: { canvas.updateColor($0) }
                        )
                    )
                }
            }
            .padding(DS.Spacing.xl)
        }
    }
}
```

Key changes: All section labels → uppercase monospace with tracking (Heron Preston style). All colors → DS tokens.

- [ ] **Step 2: Build to verify**

Run: `flowdeck build --project ios-native/Glyph/Glyph.xcodeproj --scheme Glyph`
Expected: Build succeeds

- [ ] **Step 3: Commit**

```bash
git add ios-native/Glyph/Sources/Views/StyleControlsView.swift
git commit -m "feat: migrate StyleControlsView — uppercase monospace labels, DS tokens"
```

---

### Task 6: Migrate ColorGrid.swift

**Files:**
- Modify: `Sources/Views/ColorGrid.swift`

- [ ] **Step 1: Replace GlyphTheme.accent selection ring**

Full replacement of `ColorGrid.swift`:

```swift
import SwiftUI

private typealias DS = GlyphDesignSystem

/// 4×4 grid of preset colors — curated for Instagram Stories.
struct ColorGrid: View {
    @Binding var selectedColor: Color

    /// 16 preset colors — reordered for light canvas visibility.
    private static let presets: [Color] = [
        .black,
        Color(hex: 0x424242),
        Color(hex: 0x9E9E9E),
        Color(hex: 0xE0E0E0),
        .white,
        Color(hex: 0x1A1A1A),
        Color(hex: 0xFF3B30),  // Red
        Color(hex: 0xFF8A65),  // Orange
        Color(hex: 0xFFD54F),  // Yellow
        Color(hex: 0x34C759),  // Green
        Color(hex: 0x4DD0E1),  // Cyan
        Color(hex: 0x64B5F6),  // Blue
        Color(hex: 0x7986CB),  // Indigo
        Color(hex: 0xBA68C8),  // Purple
        Color(hex: 0xF06292),  // Pink
        Color(hex: 0xA1887F),  // Brown
    ]

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 8)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(Array(Self.presets.enumerated()), id: \.offset) { _, color in
                Circle()
                    .fill(color)
                    .frame(width: 32, height: 32)
                    .overlay {
                        // White swatch needs a border to be visible on light bg
                        if color == .white {
                            Circle()
                                .stroke(DS.Color.border, lineWidth: 1)
                        }
                    }
                    .overlay {
                        if selectedColor == color {
                            Circle()
                                .stroke(DS.Color.accent, lineWidth: 2.5)
                                .padding(-3)
                        }
                    }
                    .onTapGesture {
                        selectedColor = color
                        UISelectionFeedbackGenerator().selectionChanged()
                    }
            }
        }
    }
}
```

Key changes: `GlyphTheme.accent` → `DS.Color.accent`. Color presets now use `Color(hex:)` initializer. Black moved to first position (more useful on light canvas). White swatch gets a border so it's visible on the light sheet.

- [ ] **Step 2: Build to verify**

Run: `flowdeck build --project ios-native/Glyph/Glyph.xcodeproj --scheme Glyph`
Expected: Build succeeds

- [ ] **Step 3: Commit**

```bash
git add ios-native/Glyph/Sources/Views/ColorGrid.swift
git commit -m "feat: migrate ColorGrid — DS tokens, light-bg color order, hex init"
```

---

### Task 7: Migrate FontPickerSheet.swift

**Files:**
- Modify: `Sources/Views/FontPickerSheet.swift`

- [ ] **Step 1: Replace all GlyphTheme references**

Full replacement of `FontPickerSheet.swift`:

```swift
import SwiftUI
import UniformTypeIdentifiers

private typealias DS = GlyphDesignSystem

/// Bottom sheet for browsing and importing fonts.
struct FontPickerSheet: View {
    @Environment(CanvasViewModel.self) private var canvas
    @Environment(FontLibraryViewModel.self) private var fontLibrary
    @Environment(\.dismiss) private var dismiss

    @State private var showImporter = false
    @State private var importError = false

    var body: some View {
        NavigationStack {
            List {
                Section("Built-in") {
                    ForEach(fontLibrary.bundledFonts) { entry in
                        fontRow(entry)
                    }
                }

                if !fontLibrary.customFonts.isEmpty {
                    Section("Your Fonts") {
                        ForEach(fontLibrary.customFonts) { entry in
                            fontRow(entry)
                        }
                        .onDelete { indexSet in
                            let customs = fontLibrary.customFonts
                            for index in indexSet {
                                fontLibrary.removeFont(id: customs[index].id)
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(DS.Color.surface)
            .navigationTitle("Fonts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showImporter = true
                    } label: {
                        Text("IMPORT")
                            .font(DS.Typography.label)
                            .tracking(1.5)
                            .foregroundStyle(DS.Color.accent)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Text("DONE")
                            .font(DS.Typography.label)
                            .tracking(1.5)
                            .foregroundStyle(DS.Color.accent)
                    }
                }
            }
            .fileImporter(
                isPresented: $showImporter,
                allowedContentTypes: [
                    UTType(filenameExtension: "ttf") ?? .data,
                    UTType(filenameExtension: "otf") ?? .data,
                ],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        let success = fontLibrary.importFont(from: url)
                        if success, let last = fontLibrary.fonts.last {
                            canvas.updateFont(last.familyName)
                        } else {
                            importError = true
                        }
                    }
                case .failure:
                    importError = true
                }
            }
            .alert("Import Failed", isPresented: $importError) {
                Button("OK") {}
            } message: {
                Text("Couldn't load this font file. Make sure it's a valid .ttf or .otf.")
            }
        }
    }

    @ViewBuilder
    private func fontRow(_ entry: FontEntry) -> some View {
        Button {
            canvas.updateFont(entry.familyName)
            UISelectionFeedbackGenerator().selectionChanged()
            dismiss()
        } label: {
            HStack {
                Text(canvas.selectedOverlay?.text.isEmpty == false
                     ? canvas.selectedOverlay!.text
                     : entry.displayName)
                    .font(.custom(entry.familyName, size: 20))
                    .foregroundStyle(DS.Color.textPrimary)
                    .lineLimit(1)

                Spacer()

                if canvas.selectedOverlay?.fontFamily == entry.familyName {
                    Image(systemName: "checkmark")
                        .foregroundStyle(DS.Color.accent)
                }
            }
            .padding(.vertical, DS.Spacing.xs)
        }
        .listRowBackground(DS.Color.canvas)
    }
}
```

Key changes: Text colors → dark on light. Toolbar buttons → uppercase monospace. Row backgrounds → canvas white. All `GlyphTheme.*` → `DS.*`.

- [ ] **Step 2: Build to verify**

Run: `flowdeck build --project ios-native/Glyph/Glyph.xcodeproj --scheme Glyph`
Expected: Build succeeds

- [ ] **Step 3: Commit**

```bash
git add ios-native/Glyph/Sources/Views/FontPickerSheet.swift
git commit -m "feat: migrate FontPickerSheet — light bg, monospace toolbar buttons"
```

---

### Task 8: Migrate ExportSheet.swift

**Files:**
- Modify: `Sources/Views/ExportSheet.swift`

- [ ] **Step 1: Replace all GlyphTheme references**

Full replacement of `ExportSheet.swift`:

```swift
import SwiftUI

private typealias DS = GlyphDesignSystem

/// Bottom sheet with export actions: Instagram, Photos, Clipboard.
struct ExportSheet: View {
    @Environment(CanvasViewModel.self) private var canvas
    @Environment(\.dismiss) private var dismiss

    @State private var isExporting = false
    @State private var toastMessage: String?
    @State private var showInstagramAlert = false

    var body: some View {
        VStack(spacing: DS.Spacing.lg) {
            Text("EXPORT")
                .font(DS.Typography.label)
                .tracking(1.5)
                .foregroundStyle(DS.Color.textTertiary)
                .padding(.top, DS.Spacing.xs)

            // Instagram Stories — primary action
            Button {
                Task { await exportToInstagram() }
            } label: {
                Label("Share to Instagram Stories", systemImage: "paperplane.fill")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(DS.Color.textPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(DS.Color.accent, in: RoundedRectangle(cornerRadius: DS.Radius.md))
            }
            .disabled(isExporting)

            // Save to Photos
            Button {
                Task { await saveToPhotos() }
            } label: {
                Label("Save to Photos", systemImage: "photo.on.rectangle")
                    .font(.body.weight(.medium))
                    .foregroundStyle(DS.Color.textPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(DS.Color.canvas, in: RoundedRectangle(cornerRadius: DS.Radius.md))
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.Radius.md)
                            .stroke(DS.Color.border, lineWidth: 1)
                    )
            }
            .disabled(isExporting)

            // Copy to Clipboard
            Button {
                copyToClipboard()
            } label: {
                Label("Copy Image", systemImage: "doc.on.doc")
                    .font(.body.weight(.medium))
                    .foregroundStyle(DS.Color.textSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(DS.Color.canvas, in: RoundedRectangle(cornerRadius: DS.Radius.md))
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.Radius.md)
                            .stroke(DS.Color.border, lineWidth: 1)
                    )
            }
            .disabled(isExporting)
        }
        .padding(.horizontal, DS.Spacing.xl)
        .padding(.bottom, DS.Spacing.xl)
        .overlay {
            if let message = toastMessage {
                VStack {
                    Text(message)
                        .font(DS.Typography.caption)
                        .foregroundStyle(DS.Color.textPrimary)
                        .padding(.horizontal, DS.Spacing.lg)
                        .padding(.vertical, DS.Spacing.md)
                        .background(.ultraThinMaterial, in: Capsule())
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation { toastMessage = nil }
                    }
                }
            }
        }
        .animation(.easeInOut, value: toastMessage)
        .alert("Instagram Not Installed", isPresented: $showInstagramAlert) {
            Button("Save to Photos Instead") {
                Task { await saveToPhotos() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Install Instagram to share stickers directly to Stories.")
        }
    }

    // MARK: - Export Actions

    private func renderImage() -> UIImage? {
        let canvasSize = CGSize(width: 1080, height: 1920)
        return ExportEngine.renderOverlays(canvas.overlays, canvasSize: canvasSize)
    }

    private func exportToInstagram() async {
        isExporting = true
        defer { isExporting = false }

        guard InstagramSharer.isAvailable else {
            showInstagramAlert = true
            return
        }

        guard let image = renderImage() else {
            showToast("Export failed")
            return
        }

        let success = await InstagramSharer.shareSticker(image)
        if success {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            dismiss()
        } else {
            showToast("Sharing failed")
        }
    }

    private func saveToPhotos() async {
        isExporting = true
        defer { isExporting = false }

        guard let image = renderImage() else {
            showToast("Export failed")
            return
        }

        _ = await InstagramSharer.saveToPhotos(image)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        showToast("Saved to Photos!")
    }

    private func copyToClipboard() {
        guard let image = renderImage() else {
            showToast("Export failed")
            return
        }

        InstagramSharer.copyToClipboard(image)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        showToast("Copied!")
    }

    private func showToast(_ message: String) {
        withAnimation { toastMessage = message }
    }
}
```

Key changes: Primary button → electric green with dark text. Secondary buttons → white canvas bg with border stroke (Things style). Title → uppercase monospace label. All tokens from DS.

- [ ] **Step 2: Build to verify**

Run: `flowdeck build --project ios-native/Glyph/Glyph.xcodeproj --scheme Glyph`
Expected: Build succeeds

- [ ] **Step 3: Commit**

```bash
git add ios-native/Glyph/Sources/Views/ExportSheet.swift
git commit -m "feat: migrate ExportSheet — green primary button, bordered secondary, monospace header"
```

---

### Task 9: Delete GlyphTheme.swift

**Files:**
- Delete: `Sources/GlyphTheme.swift`

- [ ] **Step 1: Delete the old theme file**

```bash
git rm ios-native/Glyph/Sources/GlyphTheme.swift
```

- [ ] **Step 2: Build to verify no remaining references**

Run: `flowdeck build --project ios-native/Glyph/Glyph.xcodeproj --scheme Glyph`
Expected: Build succeeds with zero errors. If any file still references `GlyphTheme`, fix it before proceeding.

- [ ] **Step 3: Regenerate Xcode project**

Run: `cd ios-native/Glyph && xcodegen generate`
Expected: Project regenerated cleanly without the deleted file.

- [ ] **Step 4: Commit**

```bash
git add -A ios-native/Glyph/
git commit -m "chore: delete GlyphTheme.swift — fully replaced by GlyphDesignSystem"
```

---

### Task 10: Create ComponentCatalog.swift — Preview Storybook

**Files:**
- Create: `Sources/Views/ComponentCatalog.swift`

- [ ] **Step 1: Create the preview catalog**

```swift
import SwiftUI

private typealias DS = GlyphDesignSystem

// MARK: - Color Tokens Preview

#Preview("Colors") {
    ScrollView {
        VStack(alignment: .leading, spacing: DS.Spacing.lg) {
            Text("COLOR TOKENS")
                .font(DS.Typography.label)
                .tracking(1.5)
                .foregroundStyle(DS.Color.textTertiary)
                .padding(.top, DS.Spacing.lg)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: DS.Spacing.md) {
                colorSwatch("canvas", DS.Color.canvas, bordered: true)
                colorSwatch("surface", DS.Color.surface)
                colorSwatch("surfaceAlt", DS.Color.surfaceAlt)
                colorSwatch("accent", DS.Color.accent)
                colorSwatch("textPrimary", DS.Color.textPrimary)
                colorSwatch("textSecondary", DS.Color.textSecondary)
                colorSwatch("textTertiary", DS.Color.textTertiary)
                colorSwatch("border", DS.Color.border)
                colorSwatch("error", DS.Color.error)
                colorSwatch("success", DS.Color.success)
            }
        }
        .padding(DS.Spacing.xl)
    }
    .background(DS.Color.canvas)
}

// MARK: - Typography Preview

#Preview("Typography") {
    ScrollView {
        VStack(alignment: .leading, spacing: DS.Spacing.xl) {
            Text("TYPOGRAPHY SCALE")
                .font(DS.Typography.label)
                .tracking(1.5)
                .foregroundStyle(DS.Color.textTertiary)
                .padding(.top, DS.Spacing.lg)

            Group {
                VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                    Text("DISPLAY")
                        .font(DS.Typography.label)
                        .tracking(1.5)
                        .foregroundStyle(DS.Color.textTertiary)
                    Text("Glyph — 28pt Bold")
                        .font(DS.Typography.display)
                        .foregroundStyle(DS.Color.textPrimary)
                }

                VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                    Text("TITLE")
                        .font(DS.Typography.label)
                        .tracking(1.5)
                        .foregroundStyle(DS.Color.textTertiary)
                    Text("Font Library — 20pt Semibold")
                        .font(DS.Typography.title)
                        .foregroundStyle(DS.Color.textPrimary)
                }

                VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                    Text("BODY")
                        .font(DS.Typography.label)
                        .tracking(1.5)
                        .foregroundStyle(DS.Color.textTertiary)
                    Text("Type your text, pick a font, share to Stories — 16pt Regular")
                        .font(DS.Typography.body)
                        .foregroundStyle(DS.Color.textPrimary)
                }

                VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                    Text("CAPTION")
                        .font(DS.Typography.label)
                        .tracking(1.5)
                        .foregroundStyle(DS.Color.textTertiary)
                    Text("Playfair Display · Bold · 24pt — 13pt Regular")
                        .font(DS.Typography.caption)
                        .foregroundStyle(DS.Color.textSecondary)
                }

                VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                    Text("LABEL")
                        .font(DS.Typography.label)
                        .tracking(1.5)
                        .foregroundStyle(DS.Color.textTertiary)
                    Text("EXPORT · STYLE · FONT")
                        .font(DS.Typography.label)
                        .tracking(1.5)
                        .foregroundStyle(DS.Color.textTertiary)
                }
            }
        }
        .padding(DS.Spacing.xl)
    }
    .background(DS.Color.canvas)
}

// MARK: - Spacing & Radius Preview

#Preview("Spacing & Radius") {
    ScrollView {
        VStack(alignment: .leading, spacing: DS.Spacing.xl) {
            Text("SPACING SCALE")
                .font(DS.Typography.label)
                .tracking(1.5)
                .foregroundStyle(DS.Color.textTertiary)
                .padding(.top, DS.Spacing.lg)

            ForEach([
                ("xs", DS.Spacing.xs),
                ("sm", DS.Spacing.sm),
                ("md", DS.Spacing.md),
                ("lg", DS.Spacing.lg),
                ("xl", DS.Spacing.xl),
                ("xxl", DS.Spacing.xxl),
            ], id: \.0) { name, value in
                HStack {
                    Text(name.uppercased())
                        .font(DS.Typography.label)
                        .tracking(1.5)
                        .foregroundStyle(DS.Color.textTertiary)
                        .frame(width: 40, alignment: .leading)
                    Rectangle()
                        .fill(DS.Color.accent)
                        .frame(width: value * 4, height: DS.Spacing.sm)
                        .clipShape(RoundedRectangle(cornerRadius: 2))
                    Text("\(Int(value))pt")
                        .font(DS.Typography.caption)
                        .foregroundStyle(DS.Color.textSecondary)
                }
            }

            Text("CORNER RADIUS")
                .font(DS.Typography.label)
                .tracking(1.5)
                .foregroundStyle(DS.Color.textTertiary)
                .padding(.top, DS.Spacing.lg)

            HStack(spacing: DS.Spacing.md) {
                ForEach([
                    ("sm", DS.Radius.sm),
                    ("md", DS.Radius.md),
                    ("lg", DS.Radius.lg),
                    ("xl", DS.Radius.xl),
                ], id: \.0) { name, radius in
                    VStack(spacing: DS.Spacing.xs) {
                        RoundedRectangle(cornerRadius: radius)
                            .fill(DS.Color.surface)
                            .frame(width: 48, height: 48)
                            .overlay(
                                RoundedRectangle(cornerRadius: radius)
                                    .stroke(DS.Color.border, lineWidth: 1)
                            )
                        Text(name.uppercased())
                            .font(DS.Typography.label)
                            .tracking(1.5)
                            .foregroundStyle(DS.Color.textTertiary)
                    }
                }
            }
        }
        .padding(DS.Spacing.xl)
    }
    .background(DS.Color.canvas)
}

// MARK: - Buttons Preview

#Preview("Buttons") {
    VStack(spacing: DS.Spacing.lg) {
        Text("BUTTON STYLES")
            .font(DS.Typography.label)
            .tracking(1.5)
            .foregroundStyle(DS.Color.textTertiary)

        // Primary
        Text("Share to Instagram Stories")
            .font(.body.weight(.semibold))
            .foregroundStyle(DS.Color.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(DS.Color.accent, in: RoundedRectangle(cornerRadius: DS.Radius.md))

        // Secondary
        Text("Save to Photos")
            .font(.body.weight(.medium))
            .foregroundStyle(DS.Color.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(DS.Color.canvas, in: RoundedRectangle(cornerRadius: DS.Radius.md))
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.md)
                    .stroke(DS.Color.border, lineWidth: 1)
            )

        // Ghost
        Text("Copy Image")
            .font(.body.weight(.medium))
            .foregroundStyle(DS.Color.textSecondary)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
    }
    .padding(DS.Spacing.xl)
    .background(DS.Color.surface)
}

// MARK: - Helpers

private func colorSwatch(_ name: String, _ color: Color, bordered: Bool = false) -> some View {
    VStack(spacing: DS.Spacing.xs) {
        RoundedRectangle(cornerRadius: DS.Radius.sm)
            .fill(color)
            .frame(height: 48)
            .overlay {
                if bordered {
                    RoundedRectangle(cornerRadius: DS.Radius.sm)
                        .stroke(DS.Color.border, lineWidth: 1)
                }
            }
        Text(name)
            .font(DS.Typography.label)
            .foregroundStyle(DS.Color.textSecondary)
    }
}
```

- [ ] **Step 2: Build to verify**

Run: `flowdeck build --project ios-native/Glyph/Glyph.xcodeproj --scheme Glyph`
Expected: Build succeeds. Previews render in Xcode canvas.

- [ ] **Step 3: Commit**

```bash
git add ios-native/Glyph/Sources/Views/ComponentCatalog.swift
git commit -m "feat: add ComponentCatalog — SwiftUI preview Storybook for all tokens"
```

---

### Task 11: Visual Verification on Device

**Files:** None (verification only)

- [ ] **Step 1: Build and run on senik device**

Run: `flowdeck run --project ios-native/Glyph/Glyph.xcodeproj --scheme Glyph --device senik`
Expected: App launches with light theme, electric green accents, white canvas.

- [ ] **Step 2: Visual check — main canvas**

Verify:
- White canvas background
- Top toolbar shows "ADD TEXT" and "EXPORT" in monospace uppercase
- Adding text creates a black text overlay on white
- Bottom controls are white circles with soft shadows

- [ ] **Step 3: Visual check — sheets**

Verify:
- Style controls sheet: light grey background, uppercase monospace labels (SIZE, SPACING, ALIGN, COLOR), green slider tint
- Font picker: light background, dark text previews, monospace IMPORT/DONE buttons
- Export sheet: green primary button with dark text, white bordered secondary buttons

- [ ] **Step 4: Screenshot and commit verification**

Take a screenshot via FlowDeck if available, then commit any final adjustments.
