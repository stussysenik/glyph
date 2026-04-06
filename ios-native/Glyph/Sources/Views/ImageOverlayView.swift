import SwiftUI

struct ImageOverlayView: View {
    private typealias DS = GlyphDesignSystem

    var layer: ImageLayer
    var isSelected: Bool
    var onSelect: () -> Void
    var onLongPress: () -> Void
    var onPositionChange: (CGSize) -> Void
    var onScaleChange: (CGFloat) -> Void
    var onRotationChange: (Angle) -> Void

    @Environment(HapticsService.self) private var haptics
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let nudge: CGFloat = 10
    private let baseWidth: CGFloat = 200

    @GestureState private var dragOffset: CGSize = .zero
    @GestureState private var gestureScale: CGFloat = 1.0
    @GestureState private var gestureRotation: Angle = .zero
    @State private var showDegreeBadge = false
    @State private var badgeWorkItem: DispatchWorkItem?

    var body: some View {
        Image(uiImage: layer.image)
            .resizable()
            .aspectRatio(layer.aspectRatio, contentMode: .fit)
            .frame(width: baseWidth)
            .scaleEffect(layer.scale * gestureScale)
            .rotationEffect(layer.rotation + gestureRotation)
            .offset(
                x: layer.position.width + dragOffset.width,
                y: layer.position.height + dragOffset.height
            )
            .overlay(selectionCorners)
            .overlay(alignment: .top) { degreeBadge }
            .opacity(layer.isVisible ? 1 : 0)
            .allowsHitTesting(layer.isVisible)
            .gesture(layer.isLocked ? nil : combinedGesture)
            .onTapGesture(count: 2) { handleDoubleTap() }
            .onTapGesture { onSelect() }
            .onLongPressGesture(minimumDuration: 0.4) { onLongPress() }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Image layer: \(layer.name)")
            .accessibilityHint(isSelected ? "Selected. Use actions for more options." : "Double-tap to select.")
            .accessibilityAddTraits(isSelected ? [.isSelected, .isButton, .isImage] : [.isButton, .isImage])
            .accessibilityValue(layer.isLocked ? "Locked" : "")
            .accessibilityActions { accessibilityActions }
    }

    // MARK: - Double Tap

    private func handleDoubleTap() {
        let current = layer.rotation
        if RotationSnapEngine.snap(current) != nil {
            onRotationChange(.zero)
        } else if let snapped = RotationSnapEngine.snap(current) {
            onRotationChange(snapped)
        } else {
            onRotationChange(RotationSnapEngine.nearestCardinal(current))
        }
        haptics.rotationSnap()
    }

    // MARK: - Degree Badge

    @ViewBuilder
    private var degreeBadge: some View {
        if showDegreeBadge {
            let total = layer.rotation + gestureRotation
            let deg = Int(total.degrees.rounded())
            let isCardinal = RotationSnapEngine.snap(total) != nil
            Text(isCardinal ? "\(Int(RotationSnapEngine.snap(total)?.degrees ?? 0))°" : "\(deg)°")
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(isCardinal ? DS.Color.accent : DS.Color.textSecondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(DS.Color.surface, in: Capsule())
                .shadow(color: .black.opacity(0.12), radius: 4, y: 2)
                .offset(y: -28)
                .transition(reduceMotion ? .opacity : .scale.combined(with: .opacity))
        }
    }

    private func flashBadge() {
        badgeWorkItem?.cancel()
        withAnimation(.easeOut(duration: 0.15)) { showDegreeBadge = true }
        let work = DispatchWorkItem {
            withAnimation(.easeOut(duration: 0.3)) { showDegreeBadge = false }
        }
        badgeWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2, execute: work)
    }

    // MARK: - Selection Corners (iA Writer style)

    @ViewBuilder
    private var selectionCorners: some View {
        if isSelected {
            let color = layer.isLocked ? DS.Color.textTertiary : DS.Color.accent
            let dash: [CGFloat] = layer.isLocked ? [6, 3] : []
            GeometryReader { geo in
                let len: CGFloat = 14
                let pad: CGFloat = 6
                let w = geo.size.width + pad * 2
                let h = geo.size.height + pad * 2
                Canvas { ctx, _ in
                    var path = Path()
                    path.move(to: CGPoint(x: pad, y: pad + len))
                    path.addLine(to: CGPoint(x: pad, y: pad))
                    path.addLine(to: CGPoint(x: pad + len, y: pad))
                    path.move(to: CGPoint(x: w - pad - len, y: pad))
                    path.addLine(to: CGPoint(x: w - pad, y: pad))
                    path.addLine(to: CGPoint(x: w - pad, y: pad + len))
                    path.move(to: CGPoint(x: w - pad, y: h - pad - len))
                    path.addLine(to: CGPoint(x: w - pad, y: h - pad))
                    path.addLine(to: CGPoint(x: w - pad - len, y: h - pad))
                    path.move(to: CGPoint(x: pad + len, y: h - pad))
                    path.addLine(to: CGPoint(x: pad, y: h - pad))
                    path.addLine(to: CGPoint(x: pad, y: h - pad - len))
                    ctx.stroke(path, with: .color(color),
                               style: StrokeStyle(lineWidth: 2.5, dash: dash))
                }
                .frame(width: w, height: h)
                .position(x: geo.size.width / 2, y: geo.size.height / 2)
            }
            .padding(-6)
            .allowsHitTesting(false)
        }
    }

    // MARK: - Accessibility Actions

    @ViewBuilder
    private var accessibilityActions: some View {
        Button("Enter multi-select") { onLongPress() }
        if !layer.isLocked {
            Button("Move up")    { onPositionChange(CGSize(width: layer.position.width, height: layer.position.height - nudge)) }
            Button("Move down")  { onPositionChange(CGSize(width: layer.position.width, height: layer.position.height + nudge)) }
            Button("Move left")  { onPositionChange(CGSize(width: layer.position.width - nudge, height: layer.position.height)) }
            Button("Move right") { onPositionChange(CGSize(width: layer.position.width + nudge, height: layer.position.height)) }
            Button("Scale up")   { onScaleChange(layer.scale * 1.1) }
            Button("Scale down") { onScaleChange(layer.scale * 0.9) }
            Button("Rotate 15° clockwise")         { onRotationChange(layer.rotation + .degrees(15)) }
            Button("Rotate 15° counter-clockwise") { onRotationChange(layer.rotation - .degrees(15)) }
        }
    }

    // MARK: - Gestures

    private var combinedGesture: some Gesture {
        SimultaneousGesture(
            DragGesture()
                .updating($dragOffset) { v, s, _ in s = v.translation }
                .onEnded { onPositionChange(CGSize(
                    width: layer.position.width + $0.translation.width,
                    height: layer.position.height + $0.translation.height
                )) },
            SimultaneousGesture(
                MagnificationGesture()
                    .updating($gestureScale) { v, s, _ in s = v }
                    .onEnded { onScaleChange(layer.scale * $0) },
                RotationGesture()
                    .updating($gestureRotation) { v, s, _ in
                        s = v
                        let total = layer.rotation + v
                        if RotationSnapEngine.snap(total) != nil { haptics.rotationSnap() }
                    }
                    .onEnded { value in
                        let final = layer.rotation + value
                        if let snapped = RotationSnapEngine.snap(final) {
                            onRotationChange(snapped)
                            haptics.rotationSnap()
                            UIAccessibility.post(notification: .announcement,
                                argument: "Snapped to \(Int(snapped.degrees)) degrees")
                        } else {
                            onRotationChange(final)
                        }
                        flashBadge()
                    }
            )
        )
    }
}
