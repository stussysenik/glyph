import SwiftUI

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

// MARK: - Rotation Snap

/// Snaps rotation angles to cardinal values (0°, 90°, 180°, 270°).
/// Provides the same magnetic "click" feel that Procreate and iOS Camera
/// offer when rotating — a subtle haptic anchor that makes free-form
/// rotation feel precise.
enum RotationSnapEngine {
    /// Cardinal angles in degrees. Includes ±equivalents so snapping
    /// works regardless of rotation direction.
    static let cardinals: [CGFloat] = [0, 90, 180, 270, -90, -180, -270, 360, -360]

    /// Default snap threshold in degrees — narrow enough to avoid
    /// accidental triggers, wide enough to feel magnetic.
    static let defaultThreshold: Double = 5

    /// If `angle` is within `threshold` degrees of any cardinal angle,
    /// returns that cardinal angle. Otherwise returns `nil`.
    ///
    /// The result is always normalised to [0°, 360°).
    static func snap(_ angle: Angle, threshold: Double = defaultThreshold) -> Angle? {
        let degrees = angle.degrees
        let thresholdDeg = threshold

        for cardinal in cardinals {
            if abs(degrees - cardinal) <= thresholdDeg {
                // Normalize to [0, 360)
                var snapped = cardinal
                snapped = snapped.truncatingRemainder(dividingBy: 360)
                if snapped < 0 { snapped += 360 }
                return .degrees(snapped)
            }
        }
        return nil
    }

    /// Convenience: returns the nearest cardinal angle regardless of
    /// threshold. Useful for double-tap "snap to nearest 90°" gesture.
    static func nearestCardinal(_ angle: Angle) -> Angle {
        let degrees = angle.degrees
        var nearest: CGFloat = 0
        var smallestDelta: CGFloat = .infinity
        for cardinal in cardinals {
            let delta = abs(degrees - cardinal)
            if delta < smallestDelta {
                smallestDelta = delta
                nearest = cardinal
            }
        }
        var snapped = nearest.truncatingRemainder(dividingBy: 360)
        if snapped < 0 { snapped += 360 }
        return .degrees(snapped)
    }
}
