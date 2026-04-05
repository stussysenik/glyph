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

    @GestureState private var dragOffset: CGSize = .zero
    @GestureState private var gestureScale: CGFloat = 1.0
    @GestureState private var gestureRotation: Angle = .zero

    private let baseWidth: CGFloat = 200

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
            .overlay(selectionBorder)
            .opacity(layer.isVisible ? 1 : 0)
            .allowsHitTesting(layer.isVisible)
            .gesture(layer.isLocked ? nil : combinedGesture)
            .onTapGesture { onSelect() }
            .onLongPressGesture(minimumDuration: 0.4) { onLongPress() }
    }

    @ViewBuilder
    private var selectionBorder: some View {
        if isSelected {
            RoundedRectangle(cornerRadius: DS.Radius.sm)
                .stroke(
                    layer.isLocked ? DS.Color.textTertiary : DS.Color.accent,
                    style: StrokeStyle(lineWidth: 2, dash: layer.isLocked ? [6, 3] : [])
                )
                .padding(-4)
        }
    }

    private var combinedGesture: some Gesture {
        SimultaneousGesture(
            DragGesture()
                .updating($dragOffset) { value, state, _ in state = value.translation }
                .onEnded { value in
                    onPositionChange(CGSize(
                        width: layer.position.width + value.translation.width,
                        height: layer.position.height + value.translation.height
                    ))
                },
            SimultaneousGesture(
                MagnificationGesture()
                    .updating($gestureScale) { value, state, _ in state = value }
                    .onEnded { value in onScaleChange(layer.scale * value) },
                RotationGesture()
                    .updating($gestureRotation) { value, state, _ in state = value }
                    .onEnded { value in onRotationChange(layer.rotation + value) }
            )
        )
    }
}
