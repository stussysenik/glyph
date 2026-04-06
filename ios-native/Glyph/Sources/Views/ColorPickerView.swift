instagram-story-builder/ios-native/Glyph/Sources/Views/ColorPickerView.swift
```
```swift
import SwiftUI
import UIKit

private typealias DS = GlyphDesignSystem

/// Tabbed color picker: palette presets, HSB wheel, eyedropper.
struct ColorPickerView: View {
    @Binding var selectedColor: Color
    @Environment(HapticsService.self) private var haptics
    @Environment(SettingsViewModel.self) private var settings

    @State private var activeTab: Tab = .palette

    private enum Tab: Int, CaseIterable {
        case palette, wheel, eyedropper
        var icon: String {
            switch self {
            case .palette:    "paintbrush.pointed"
            case .wheel:      "circle.circle"
            case .eyedropper: "eyedropper"
            }
        }
        var label: String {
            switch self {
            case .palette:    "Palette"
            case .wheel:      "Color wheel"
            case .eyedropper: "Eyedropper"
            }
        }
    }

    var body: some View {
        VStack(spacing: DS.Spacing.md) {
            tabBar
            tabContent
            if !settings.recentColors.isEmpty { recentStrip }
        }
    }

    // MARK: - Tab Bar

    private var tabBar: some View {
        HStack(spacing: DS.Spacing.lg) {
            ForEach(Tab.allCases, id: \.rawValue) { tab in
                Button {
                    activeTab = tab
                    haptics.selectionChanged()
                } label: {
                    Image(systemName: tab.icon)
                        .font(.body)
                        .foregroundStyle(activeTab == tab ? DS.Color.accent : DS.Color.textTertiary)
                        .frame(width: 44, height: 44)
                        .background(
                            activeTab == tab ? DS.Color.accentSubtle : .clear,
                            in: RoundedRectangle(cornerRadius: DS.Radius.sm)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(tab.label)
                .accessibilityHint("Switch to \(tab.label) tab")
                .accessibilityAddTraits(activeTab == tab ? .isSelected : [])
            }
        }
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var tabContent: some View {
        switch activeTab {
        case .palette:
            ColorGrid(
                selectedColor: Binding(
                    get: { selectedColor },
                    set: { color in
                        selectedColor = color
                        recordRecent(color)
                    }
                )
            )
        case .wheel:
            WheelTab(color: $selectedColor, onCommit: recordRecent)
        case .eyedropper:
            EyedropperTab(color: $selectedColor, onCommit: recordRecent)
        }
    }

    // MARK: - Recent Strip

    private var recentStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DS.Spacing.sm) {
                ForEach(settings.recentColors, id: \.self) { hex in
                    let color = Self.colorFromHex(hex)
                    Button {
                        selectedColor = color
                        recordRecent(color)
                        haptics.selectionChanged()
                    } label: {
                        Circle()
                            .fill(color)
                            .frame(width: 24, height: 24)
                            .overlay(Circle().stroke(DS.Color.border, lineWidth: 0.5))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Recent color \(hex)")
                    .accessibilityHint("Apply this color")
                }
            }
            .padding(.vertical, DS.Spacing.xs)
        }
    }

    // MARK: - Helpers

    private func recordRecent(_ color: Color) {
        settings.addRecentColor(hex: Self.hexString(from: color))
    }

    static func hexString(from color: Color) -> String {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(color).getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }

    static func colorFromHex(_ hex: String) -> Color {
        let clean = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        guard let v = UInt(clean, radix: 16) else { return .white }
        return Color(hex: v)
    }
}

// MARK: - WheelTab

private struct WheelTab: View {
    @Binding var color: Color
    let onCommit: (Color) -> Void

    @State private var hue: Double
    @State private var sat: Double
    @State private var bri: Double

    private let outerR: CGFloat = 120
    private let ringW: CGFloat = 22
    private let sqSide: CGFloat = 128

    init(color: Binding<Color>, onCommit: @escaping (Color) -> Void) {
        self._color = color
        self.onCommit = onCommit
        let ui = UIColor(color.wrappedValue)
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ui.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        _hue = State(initialValue: Double(h))
        _sat = State(initialValue: Double(s))
        _bri = State(initialValue: Double(b))
    }

    var body: some View {
        VStack(spacing: DS.Spacing.md) {
            ZStack {
                hueRing.gesture(ringDrag)
                sbSquare.gesture(sqDrag)
            }
            .frame(width: outerR * 2, height: outerR * 2)
            preview
        }
    }

    // MARK: Hue Ring

    private var hueRing: some View {
        Circle()
            .strokeBorder(
                AngularGradient(
                    colors: (0...36).map { Color(hue: Double($0) / 36, saturation: 1, brightness: 1) },
                    center: .center
                ),
                lineWidth: ringW
            )
            .overlay {
                let a = hue * 2 * .pi
                let r = outerR - ringW / 2
                Circle()
                    .fill(.white)
                    .frame(width: ringW - 4, height: ringW - 4)
                    .shadow(radius: 1)
                    .overlay(Circle().stroke(.black.opacity(0.2), lineWidth: 1))
                    .offset(x: cos(a) * r, y: sin(a) * r)
            }
    }

    // MARK: Saturation / Brightness Square

    private var sbSquare: some View {
        ZStack(alignment: .topLeading) {
            Rectangle()
                .fill(Color(hue: hue, saturation: 1, brightness: 1))
            LinearGradient(
                stops: [.init(color: .white, location: 0), .init(color: .clear, location: 1)],
                startPoint: .leading, endPoint: .trailing
            )
            LinearGradient(
                stops: [.init(color: .clear, location: 0), .init(color: .black, location: 1)],
                startPoint: .top, endPoint: .bottom
            )
            Circle()
                .fill(.clear)
                .frame(width: 14, height: 14)
                .overlay(Circle().stroke(.white, lineWidth: 2).shadow(radius: 1))
                .offset(x: sat * sqSide - 7, y: (1 - bri) * sqSide - 7)
        }
        .frame(width: sqSide, height: sqSide)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.sm))
    }

    // MARK: Gestures

    private var ringDrag: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { v in
                let dx = v.location.x - outerR
                let dy = v.location.y - outerR
                var a = atan2(dy, dx)
                if a < 0 { a += 2 * .pi }
                hue = a / (2 * .pi)
                pushColor()
            }
            .onEnded { _ in onCommit(color) }
    }

    private var sqDrag: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { v in
                sat = clamp(v.location.x / sqSide)
                bri = clamp(1 - v.location.y / sqSide)
                pushColor()
            }
            .onEnded { _ in onCommit(color) }
    }

    private var preview: some View {
        Circle()
            .fill(color)
            .frame(width: 28, height: 28)
            .overlay(Circle().stroke(DS.Color.border, lineWidth: 1))
            .accessibilityLabel("Selected color preview")
    }

    private func pushColor() {
        color = Color(hue: hue, saturation: sat, brightness: bri)
    }

    private func clamp(_ v: CGFloat) -> Double {
        min(max(Double(v), 0), 1)
    }
}

// MARK: - EyedropperTab

private struct EyedropperTab: View {
    @Binding var color: Color
    let onCommit: (Color) -> Void
    @Environment(CanvasViewModel.self) private var canvas
    @Environment(HapticsService.self) private var haptics

    @State private var image: UIImage?
    @State private var touch: CGPoint = .zero
    @State private var dragging = false

    private let dispH: CGFloat = 200
    private let magD: CGFloat = 40
    private let magZ: CGFloat = 4

    var body: some View {
        Group {
            if let img = image {
                eyedropperContent(img)
            } else {
                ProgressView()
                    .frame(height: dispH)
                    .accessibilityLabel("Loading canvas preview")
            }
        }
        .onAppear { capture() }
    }

    private func eyedropperContent(_ img: UIImage) -> some View {
        let w = dispH * img.size.width / img.size.height
        return ZStack {
            Image(uiImage: img)
                .resizable()
                .frame(width: w, height: dispH)
                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.sm))
                .overlay(
                    RoundedRectangle(cornerRadius: DS.Radius.sm)
                        .stroke(DS.Color.border, lineWidth: 1)
                )

            if dragging {
                magnifier(img, w: w)
                    .position(touch)
                    .allowsHitTesting(false)
            }
        }
        .frame(width: w, height: dispH)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { v in
                    touch = v.location
                    dragging = true
                }
                .onEnded { v in
                    let pt = CGPoint(
                        x: v.location.x / w * img.size.width,
                        y: v.location.y / dispH * img.size.height
                    )
                    if let c = Self.samplePixel(in: img, at: pt) {
                        color = c
                        onCommit(c)
                        haptics.selectionChanged()
                    }
                    dragging = false
                }
        )
        .accessibilityLabel("Canvas preview for color sampling")
        .accessibilityHint("Drag to pick a color from the canvas")
    }

    // MARK: Magnifier

    private func magnifier(_ img: UIImage, w: CGFloat) -> some View {
        let d = magD
        let z = magZ
        return ZStack {
            Image(uiImage: img)
                .resizable()
                .frame(width: w * z, height: dispH * z)
                .position(
                    x: d / 2 + (w / 2 - touch.x) * z,
                    y: d / 2 + (dispH / 2 - touch.y) * z
                )
            Circle()
                .stroke(.black.opacity(0.4), lineWidth: 1)
                .frame(width: 6, height: 6)
        }
        .frame(width: d, height: d)
        .clipped()
        .clipShape(Circle())
        .overlay(Circle().stroke(.white, lineWidth: 2).shadow(radius: 3))
    }

    // MARK: Capture & Sample

    private func capture() {
        image = ExportEngine.renderLayers(
            canvas.layers,
            background: canvas.background,
            canvasSize: CGSize(width: 360, height: 640)
        )
    }

    private static func samplePixel(in image: UIImage, at point: CGPoint) -> Color? {
        guard let cg = image.cgImage else { return nil }
        let sx = CGFloat(cg.width) / image.size.width
        let sy = CGFloat(cg.height) / image.size.height
        let px = Int(point.x * sx), py = Int(point.y * sy)
        guard px >= 0, px < cg.width, py >= 0, py < cg.height else { return nil }

        let w = cg.width, h = cg.height
        guard let ctx = CGContext(
            data: nil, width: w, height: h,
            bitsPerComponent: 8, bytesPerRow: w * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        ctx.translateBy(x: 0, y: CGFloat(h))
        ctx.scaleBy(x: 1, y: -1)
        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))

        guard let data = ctx.data else { return nil }
        let ptr = data.bindMemory(to: UInt8.self, capacity: w * 4 * h)
        let off = w * 4 * py + 4 * px
        return Color(
            red: Double(ptr[off]) / 255,
            green: Double(ptr[off + 1]) / 255,
            blue: Double(ptr[off + 2]) / 255
        )
    }
}
