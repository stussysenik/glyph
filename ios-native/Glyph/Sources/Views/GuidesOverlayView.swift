import SwiftUI

private typealias DS = GlyphDesignSystem

struct GuidesOverlayView: View {
    let canvasSize: CGSize
    let showGrid: Bool
    let gridType: GridType
    let gridColumns: Int
    let showCenterGuides: Bool
    let activeGuides: [Guide]
    var customGuides: [CustomGuide] = []
    var snapThreshold: CGFloat = 8
    var onAddCustomGuide: ((GuideAxis, CGFloat) -> Void)? = nil
    var onMoveCustomGuide: ((UUID, CGFloat) -> Void)? = nil
    var onRemoveCustomGuide: ((UUID) -> Void)? = nil

    private let gridColor = DS.Color.textPrimary.opacity(0.06)
    private let centerColor = DS.Color.accent.opacity(0.35)
    private let guideColors: [GuideKind: Color] = [
        .centerCanvas: DS.Color.accent.opacity(0.75),
        .layerEdge:    Color.cyan.opacity(0.75),
        .equalSpacing: Color.orange.opacity(0.75),
    ]
    private let customGuideColor = DS.Color.accent.opacity(0.55)
    private let snapZoneColor = DS.Color.accent.opacity(0.04)
    private let rulerHeight: CGFloat = 14
    private let phi: CGFloat = 1.6180339887

    @State private var draggingAxis: GuideAxis? = nil
    @State private var dragPosition: CGFloat? = nil

    var body: some View {
        ZStack {
            if showGrid { gridLines }
            if showCenterGuides && showGrid { centerCrosshair }
            snapZoneBands
            activeGuideLines
            customGuideLines
            if showGrid { rulerStrips }
        }
        .drawingGroup()
    }

    // MARK: - Grid

    @ViewBuilder
    private var gridLines: some View {
        Canvas { ctx, size in
            switch gridType {
            case .ruleOfThirds: drawThirds(ctx: ctx, size: size)
            case .goldenRatio:  drawGolden(ctx: ctx, size: size)
            case .even:         drawEven(ctx: ctx, size: size)
            }
        }
        .allowsHitTesting(false)
    }

    private func drawThirds(ctx: GraphicsContext, size: CGSize) {
        var p = Path()
        for i in 1...2 {
            let x = size.width * CGFloat(i) / 3, y = size.height * CGFloat(i) / 3
            p.move(to: CGPoint(x: x, y: 0)); p.addLine(to: CGPoint(x: x, y: size.height))
            p.move(to: CGPoint(x: 0, y: y)); p.addLine(to: CGPoint(x: size.width, y: y))
        }
        ctx.stroke(p, with: .color(gridColor), lineWidth: 0.5)
    }

    private func drawGolden(ctx: GraphicsContext, size: CGSize) {
        var p = Path()
        let gx1 = size.width / phi, gx2 = size.width - gx1
        let gy1 = size.height / phi, gy2 = size.height - gy1
        p.move(to: CGPoint(x: gx1, y: 0)); p.addLine(to: CGPoint(x: gx1, y: size.height))
        p.move(to: CGPoint(x: gx2, y: 0)); p.addLine(to: CGPoint(x: gx2, y: size.height))
        p.move(to: CGPoint(x: 0, y: gy1)); p.addLine(to: CGPoint(x: size.width, y: gy1))
        p.move(to: CGPoint(x: 0, y: gy2)); p.addLine(to: CGPoint(x: size.width, y: gy2))
        ctx.stroke(p, with: .color(gridColor.opacity(1.5)), lineWidth: 0.5)
    }

    private func drawEven(ctx: GraphicsContext, size: CGSize) {
        let cols = max(2, gridColumns)
        let rows = Int(round(Double(cols) * (size.height / size.width)))
        var p = Path()
        for col in 1..<cols {
            let x = size.width * CGFloat(col) / CGFloat(cols)
            p.move(to: CGPoint(x: x, y: 0)); p.addLine(to: CGPoint(x: x, y: size.height))
        }
        for row in 1..<rows {
            let y = size.height * CGFloat(row) / CGFloat(rows)
            p.move(to: CGPoint(x: 0, y: y)); p.addLine(to: CGPoint(x: size.width, y: y))
        }
        ctx.stroke(p, with: .color(gridColor), lineWidth: 0.5)
    }

    // MARK: - Center Crosshair

    @ViewBuilder
    private var centerCrosshair: some View {
        Canvas { ctx, size in
            var p = Path()
            let cx = size.width / 2, cy = size.height / 2
            p.move(to: CGPoint(x: cx, y: 0)); p.addLine(to: CGPoint(x: cx, y: size.height))
            p.move(to: CGPoint(x: 0, y: cy)); p.addLine(to: CGPoint(x: size.width, y: cy))
            ctx.stroke(p, with: .color(centerColor), style: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
        }
        .allowsHitTesting(false)
    }

    // MARK: - Snap Zone Bands

    @ViewBuilder
    private var snapZoneBands: some View {
        if !activeGuides.isEmpty {
            Canvas { ctx, size in
                let ox = size.width / 2, oy = size.height / 2, band = snapThreshold
                for guide in activeGuides {
                    let rect: CGRect
                    switch guide.axis {
                    case .vertical:
                        let x = ox + guide.position
                        rect = CGRect(x: x - band, y: 0, width: band * 2, height: size.height)
                    case .horizontal:
                        let y = oy + guide.position
                        rect = CGRect(x: 0, y: y - band, width: size.width, height: band * 2)
                    }
                    ctx.fill(Path(rect), with: .color(snapZoneColor))
                }
            }
            .allowsHitTesting(false)
        }
    }

    // MARK: - Active Guide Lines

    @ViewBuilder
    private var activeGuideLines: some View {
        Canvas { ctx, size in
            let ox = size.width / 2, oy = size.height / 2
            for guide in activeGuides {
                var p = Path()
                switch guide.axis {
                case .vertical:
                    let x = ox + guide.position
                    p.move(to: CGPoint(x: x, y: 0)); p.addLine(to: CGPoint(x: x, y: size.height))
                case .horizontal:
                    let y = oy + guide.position
                    p.move(to: CGPoint(x: 0, y: y)); p.addLine(to: CGPoint(x: size.width, y: y))
                }
                ctx.stroke(p, with: .color(guideColors[guide.kind] ?? DS.Color.accent), lineWidth: 1)
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Custom Guide Lines

    @ViewBuilder
    private var customGuideLines: some View {
        Canvas { ctx, size in
            let ox = size.width / 2, oy = size.height / 2
            for guide in customGuides {
                var p = Path()
                switch guide.axis {
                case .vertical:
                    let x = ox + guide.position
                    p.move(to: CGPoint(x: x, y: 0)); p.addLine(to: CGPoint(x: x, y: size.height))
                case .horizontal:
                    let y = oy + guide.position
                    p.move(to: CGPoint(x: 0, y: y)); p.addLine(to: CGPoint(x: size.width, y: y))
                }
                ctx.stroke(p, with: .color(customGuideColor), style: StrokeStyle(lineWidth: 1, dash: [6, 4]))
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Ruler Strips

    @ViewBuilder
    private var rulerStrips: some View {
        // Top ruler — drag down to create horizontal guide
        Rectangle()
            .fill(DS.Color.textPrimary.opacity(0.03))
            .frame(height: rulerHeight)
            .frame(maxWidth: .infinity, alignment: .top)
            .contentShape(Rectangle())
            .gesture(rulerDrag(axis: .horizontal, canvasAxis: \.height))

        // Left ruler — drag right to create vertical guide
        Rectangle()
            .fill(DS.Color.textPrimary.opacity(0.03))
            .frame(width: rulerHeight)
            .frame(maxHeight: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .offset(y: rulerHeight)
            .gesture(rulerDrag(axis: .vertical, canvasAxis: \.width))

        // Live drag preview
        if let axis = draggingAxis, let pos = dragPosition {
            dragPreview(axis: axis, position: pos)
        }
    }

    @ViewBuilder
    private func dragPreview(axis: GuideAxis, position: CGFloat) -> some View {
        let ox = canvasSize.width / 2, oy = canvasSize.height / 2
        Canvas { ctx, size in
            var p = Path()
            switch axis {
            case .vertical:
                let x = ox + position
                p.move(to: CGPoint(x: x, y: 0)); p.addLine(to: CGPoint(x: x, y: size.height))
            case .horizontal:
                let y = oy + position
                p.move(to: CGPoint(x: 0, y: y)); p.addLine(to: CGPoint(x: size.width, y: y))
            }
            ctx.stroke(p, with: .color(DS.Color.accent.opacity(0.8)), lineWidth: 1)
        }
        .allowsHitTesting(false)
    }

    // MARK: - Ruler Drag Gesture

    private func rulerDrag(axis: GuideAxis, canvasAxis: KeyPath<CGSize, CGFloat>) -> some Gesture {
        DragGesture(minimumDistance: 4)
            .onChanged { value in
                let half = canvasSize[keyPath: canvasAxis] / 2
                let loc = axis == .horizontal ? value.location.y : value.location.x
                draggingAxis = axis
                dragPosition = loc - half
            }
            .onEnded { value in
                let half = canvasSize[keyPath: canvasAxis] / 2
                let loc = axis == .horizontal ? value.location.y : value.location.x
                let offset = loc - half
                if abs(offset) < half - 10 {
                    onAddCustomGuide?(axis, offset)
                }
                draggingAxis = nil; dragPosition = nil
            }
    }
}
