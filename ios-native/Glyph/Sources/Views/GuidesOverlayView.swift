import SwiftUI

private typealias DS = GlyphDesignSystem

struct GuidesOverlayView: View {
    let canvasSize: CGSize
    let showGrid: Bool
    let useRuleOfThirds: Bool
    let activeGuides: [Guide]

    private let gridColor = DS.Color.textPrimary.opacity(0.06)
    private let guideColorCenter = DS.Color.accent.opacity(0.75)
    private let guideColorEdge = Color.cyan.opacity(0.75)
    private let guideColorSpacing = Color.orange.opacity(0.75)
    private let lineWidth: CGFloat = 0.5
    private let guideLineWidth: CGFloat = 1

    var body: some View {
        ZStack {
            if showGrid { gridLines }
            activeGuideLines
        }
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private var gridLines: some View {
        Canvas { ctx, size in
            if useRuleOfThirds {
                drawRuleOfThirds(ctx: ctx, size: size)
            } else {
                drawEvenGrid(ctx: ctx, size: size)
            }
        }
    }

    private func drawRuleOfThirds(ctx: GraphicsContext, size: CGSize) {
        var path = Path()
        for i in 1...2 {
            let x = size.width * CGFloat(i) / 3
            let y = size.height * CGFloat(i) / 3
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: size.height))
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: size.width, y: y))
        }
        ctx.stroke(path, with: .color(gridColor), lineWidth: lineWidth)
    }

    private func drawEvenGrid(ctx: GraphicsContext, size: CGSize) {
        var path = Path()
        for col in 1..<8 {
            let x = size.width * CGFloat(col) / 8
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: size.height))
        }
        for row in 1..<14 {
            let y = size.height * CGFloat(row) / 14
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: size.width, y: y))
        }
        ctx.stroke(path, with: .color(gridColor), lineWidth: lineWidth)
    }

    @ViewBuilder
    private var activeGuideLines: some View {
        Canvas { ctx, size in
            let originX = size.width / 2
            let originY = size.height / 2
            for guide in activeGuides {
                let color: Color = switch guide.kind {
                case .centerCanvas: guideColorCenter
                case .layerEdge: guideColorEdge
                case .equalSpacing: guideColorSpacing
                }
                var path = Path()
                switch guide.axis {
                case .vertical:
                    let x = originX + guide.position
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: size.height))
                case .horizontal:
                    let y = originY + guide.position
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                }
                ctx.stroke(path, with: .color(color), lineWidth: guideLineWidth)
            }
        }
    }
}
