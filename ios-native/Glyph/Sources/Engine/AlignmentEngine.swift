import CoreGraphics

enum AlignmentEngine {
    static let defaultThreshold: CGFloat = 8

    static func snapPosition(
        _ position: CGSize,
        layerSize: CGSize,
        otherLayers: [LayerGeometry],
        canvasSize: CGSize,
        threshold: CGFloat = defaultThreshold
    ) -> (snapped: CGSize, guides: [Guide]) {
        var result = position
        var guides: [Guide] = []

        let halfW = layerSize.width / 2
        let halfH = layerSize.height / 2

        let layerLeft = position.width - halfW
        let layerCenterX = position.width
        let layerRight = position.width + halfW

        let layerTop = position.height - halfH
        let layerCenterY = position.height
        let layerBottom = position.height + halfH

        // Canvas center guides
        if let (snapped, _) = snap(
            candidates: [layerLeft, layerCenterX, layerRight],
            offsets: [-halfW, 0, halfW],
            to: 0,
            current: position.width,
            threshold: threshold
        ) {
            result.width = snapped
            guides.append(Guide(axis: .vertical, position: 0, kind: .centerCanvas))
        }

        if let (snapped, _) = snap(
            candidates: [layerTop, layerCenterY, layerBottom],
            offsets: [-halfH, 0, halfH],
            to: 0,
            current: position.height,
            threshold: threshold
        ) {
            result.height = snapped
            guides.append(Guide(axis: .horizontal, position: 0, kind: .centerCanvas))
        }

        // Other layer edge guides
        for other in otherLayers {
            let targets: [(CGFloat, GuideAxis)] = [
                (other.minX, .vertical), (other.centerX, .vertical), (other.maxX, .vertical),
                (other.minY, .horizontal), (other.centerY, .horizontal), (other.maxY, .horizontal),
            ]

            for (target, axis) in targets {
                if axis == .vertical {
                    if let (snapped, _) = snap(
                        candidates: [layerLeft, layerCenterX, layerRight],
                        offsets: [-halfW, 0, halfW],
                        to: target,
                        current: result.width,
                        threshold: threshold
                    ) {
                        result.width = snapped
                        guides.append(Guide(axis: .vertical, position: target, kind: .layerEdge))
                    }
                } else {
                    if let (snapped, _) = snap(
                        candidates: [layerTop, layerCenterY, layerBottom],
                        offsets: [-halfH, 0, halfH],
                        to: target,
                        current: result.height,
                        threshold: threshold
                    ) {
                        result.height = snapped
                        guides.append(Guide(axis: .horizontal, position: target, kind: .layerEdge))
                    }
                }
            }
        }

        let deduped = Dictionary(grouping: guides) { "\($0.axis)-\($0.position)" }
            .compactMap { $0.value.first }
        return (result, deduped)
    }

    private static func snap(
        candidates: [CGFloat], offsets: [CGFloat], to target: CGFloat,
        current: CGFloat, threshold: CGFloat
    ) -> (snappedCenter: CGFloat, offset: CGFloat)? {
        for (candidate, offset) in zip(candidates, offsets) {
            if abs(candidate - target) <= threshold {
                return (target - offset, offset)
            }
        }
        return nil
    }
}

struct LayerGeometry: Sendable {
    let minX, centerX, maxX: CGFloat
    let minY, centerY, maxY: CGFloat

    init(position: CGSize, size: CGSize) {
        let hw = size.width / 2
        let hh = size.height / 2
        minX = position.width - hw
        centerX = position.width
        maxX = position.width + hw
        minY = position.height - hh
        centerY = position.height
        maxY = position.height + hh
    }
}
