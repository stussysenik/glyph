import SwiftUI

private typealias DS = GlyphDesignSystem

/// A single draggable, resizable, rotatable text overlay on the canvas.
struct TextOverlayView: View {
    let overlay: TextOverlay
    let isSelected: Bool

    @Environment(CanvasViewModel.self) private var canvas

    // In-flight gesture state
    @State private var dragOffset: CGSize = .zero
    @State private var gestureScale: CGFloat = 1.0
    @State private var gestureRotation: Angle = .zero

    // Committed state from previous gestures
    @State private var lastScale: CGFloat = 1.0
    @State private var lastRotation: Angle = .zero

    var body: some View {
        Text(overlay.text.isEmpty ? "Type something" : overlay.text)
            .font(.custom(overlay.fontFamily, size: overlay.fontSize))
            .foregroundStyle(overlay.text.isEmpty ? overlay.textColor.opacity(0.4) : overlay.textColor)
            .tracking(overlay.letterSpacing)
            .multilineTextAlignment(overlay.alignment)
            .padding(8)
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(DS.Color.accent, lineWidth: 1.5)
                        .padding(4)
                }
            }
            .scaleEffect(overlay.scale * gestureScale)
            .rotationEffect(overlay.rotation + gestureRotation)
            .offset(
                x: overlay.position.width + dragOffset.width,
                y: overlay.position.height + dragOffset.height
            )
            .onTapGesture {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                canvas.selectOverlay(id: overlay.id)
            }
            .onLongPressGesture {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                canvas.selectOverlay(id: overlay.id)
                canvas.isEditing = true
            }
            .gesture(dragGesture)
            .gesture(pinchAndRotateGesture)
    }

    // MARK: - Gestures

    /// 1-finger drag to reposition.
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                dragOffset = value.translation
            }
            .onEnded { value in
                let newPosition = CGSize(
                    width: overlay.position.width + value.translation.width,
                    height: overlay.position.height + value.translation.height
                )
                canvas.updatePosition(newPosition, for: overlay.id)
                canvas.selectOverlay(id: overlay.id)
                dragOffset = .zero
            }
    }

    /// 2-finger simultaneous pinch + rotate.
    private var pinchAndRotateGesture: some Gesture {
        SimultaneousGesture(
            MagnificationGesture()
                .onChanged { value in
                    gestureScale = value / lastScale
                }
                .onEnded { value in
                    let newScale = overlay.scale * (value / lastScale)
                    canvas.updateScale(max(0.3, min(5.0, newScale)), for: overlay.id)
                    lastScale = value
                    gestureScale = 1.0
                    lastScale = 1.0
                },
            RotationGesture()
                .onChanged { value in
                    gestureRotation = value - lastRotation
                }
                .onEnded { value in
                    let newRotation = overlay.rotation + (value - lastRotation)
                    canvas.updateRotation(newRotation, for: overlay.id)
                    lastRotation = value
                    gestureRotation = .zero
                    lastRotation = .zero
                }
        )
    }
}
