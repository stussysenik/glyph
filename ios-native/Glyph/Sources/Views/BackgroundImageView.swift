import SwiftUI

struct BackgroundImageView: View {
    private typealias DS = GlyphDesignSystem

    var background: CanvasBackground
    var canvasSize: CGSize
    var onScaleChange: (CGFloat) -> Void
    var onOffsetChange: (CGSize) -> Void

    @GestureState private var gestureScale: CGFloat = 1.0
    @GestureState private var gestureDrag: CGSize = .zero

    var body: some View {
        Image(uiImage: background.image)
            .resizable()
            .scaledToFill()
            .scaleEffect(background.scale * gestureScale)
            .offset(
                x: background.offset.width + gestureDrag.width,
                y: background.offset.height + gestureDrag.height
            )
            .clipped()
            .gesture(pinchGesture)
            .gesture(panGesture)
    }

    /// Maximum offset that keeps the scaled image covering the canvas.
    private func clampedOffset(_ raw: CGSize, scale: CGFloat) -> CGSize {
        guard canvasSize.width > 0 else { return raw }
        let imgSize = background.image.size
        let fillScale = max(canvasSize.width / imgSize.width, canvasSize.height / imgSize.height)
        let scaledW = imgSize.width * fillScale * scale
        let scaledH = imgSize.height * fillScale * scale
        let maxX = max((scaledW - canvasSize.width) / 2, 0)
        let maxY = max((scaledH - canvasSize.height) / 2, 0)
        return CGSize(
            width: min(max(raw.width, -maxX), maxX),
            height: min(max(raw.height, -maxY), maxY)
        )
    }

    private var pinchGesture: some Gesture {
        MagnificationGesture()
            .updating($gestureScale) { value, state, _ in state = value }
            .onEnded { value in
                let newScale = max(1.0, min(background.scale * value, 5.0))
                onScaleChange(newScale)
                // Re-clamp offset for new scale
                let clamped = clampedOffset(background.offset, scale: newScale)
                if clamped != background.offset { onOffsetChange(clamped) }
            }
    }

    private var panGesture: some Gesture {
        DragGesture()
            .updating($gestureDrag) { value, state, _ in state = value.translation }
            .onEnded { value in
                let raw = CGSize(
                    width: background.offset.width + value.translation.width,
                    height: background.offset.height + value.translation.height
                )
                onOffsetChange(clampedOffset(raw, scale: background.scale))
            }
    }
}
