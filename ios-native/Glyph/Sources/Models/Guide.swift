import CoreGraphics
import Foundation

enum GuideAxis: Sendable {
    case horizontal
    case vertical
}

enum GuideKind: Sendable {
    case centerCanvas
    case layerEdge
    case equalSpacing
}

struct Guide: Identifiable, Sendable {
    let id: UUID
    let axis: GuideAxis
    let position: CGFloat
    let kind: GuideKind

    init(axis: GuideAxis, position: CGFloat, kind: GuideKind) {
        self.id = UUID()
        self.axis = axis
        self.position = position
        self.kind = kind
    }
}
