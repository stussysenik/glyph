import SwiftUI

struct BackgroundImageView: View {
    private typealias DS = GlyphDesignSystem

    var background: CanvasBackground
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

    private var pinchGesture: some Gesture {
        MagnificationGesture()
            .updating($gestureScale) { value, state, _ in state = value }
            .onEnded { value in onScaleChange(background.scale * value) }
    }

    private var panGesture: some Gesture {
        DragGesture()
            .updating($gestureDrag) { value, state, _ in state = value.translation }
            .onEnded { value in
                onOffsetChange(CGSize(
                    width: background.offset.width + value.translation.width,
                    height: background.offset.height + value.translation.height
                ))
            }
    }
}
