import UIKit
import SwiftUI

enum ExportEngine {

    /// Render all layers into a single PNG image.
    /// Composites: background → layers in z-order (images + text).
    static func renderLayers(
        _ layers: [any Layer],
        background: CanvasBackground?,
        canvasSize: CGSize
    ) -> UIImage? {
        let format = UIGraphicsImageRendererFormat()
        format.opaque = background != nil
        format.scale = 2.0

        let renderer = UIGraphicsImageRenderer(size: canvasSize, format: format)
        return renderer.image { context in
            let ctx = context.cgContext

            // 1. Background
            if let bg = background {
                ctx.saveGState()
                let bgSize = bg.image.size
                let scaleToFill = max(canvasSize.width / bgSize.width, canvasSize.height / bgSize.height) * bg.scale
                let drawWidth = bgSize.width * scaleToFill
                let drawHeight = bgSize.height * scaleToFill
                let drawX = (canvasSize.width - drawWidth) / 2 + bg.offset.width
                let drawY = (canvasSize.height - drawHeight) / 2 + bg.offset.height
                bg.image.draw(in: CGRect(x: drawX, y: drawY, width: drawWidth, height: drawHeight))
                ctx.restoreGState()
            }

            // 2. Layers in z-order
            let sorted = layers.sorted { $0.zIndex < $1.zIndex }
            for layer in sorted {
                guard layer.isVisible else { continue }

                if let textLayer = layer as? TextLayer {
                    drawTextLayer(textLayer, in: ctx, canvasSize: canvasSize)
                } else if let imageLayer = layer as? ImageLayer {
                    drawImageLayer(imageLayer, in: ctx, canvasSize: canvasSize)
                }
            }
        }
    }

    /// Convenience for PNG Data output.
    static func renderToPNG(
        _ layers: [any Layer],
        background: CanvasBackground?,
        canvasSize: CGSize
    ) -> Data? {
        renderLayers(layers, background: background, canvasSize: canvasSize)?.pngData()
    }

    // MARK: - Private drawing

    private static func drawTextLayer(_ layer: TextLayer, in ctx: CGContext, canvasSize: CGSize) {
        ctx.saveGState()

        let centerX = canvasSize.width / 2 + layer.position.width
        let centerY = canvasSize.height / 2 + layer.position.height
        ctx.translateBy(x: centerX, y: centerY)
        ctx.rotate(by: layer.rotation.radians)
        ctx.scaleBy(x: layer.scale, y: layer.scale)

        let font = FontLoader.uiFont(family: layer.fontFamily, size: layer.fontSize)
        let uiColor = UIColor(layer.textColor)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = nsAlignment(from: layer.alignment)

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: uiColor,
            .paragraphStyle: paragraphStyle,
            .kern: layer.letterSpacing,
        ]

        let attrString = NSAttributedString(string: layer.text, attributes: attributes)
        let textSize = attrString.boundingRect(
            with: CGSize(width: canvasSize.width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        ).size

        let drawRect = CGRect(
            x: -textSize.width / 2,
            y: -textSize.height / 2,
            width: textSize.width,
            height: textSize.height
        )
        attrString.draw(in: drawRect)

        ctx.restoreGState()
    }

    private static func drawImageLayer(_ layer: ImageLayer, in ctx: CGContext, canvasSize: CGSize) {
        ctx.saveGState()

        let centerX = canvasSize.width / 2 + layer.position.width
        let centerY = canvasSize.height / 2 + layer.position.height
        ctx.translateBy(x: centerX, y: centerY)
        ctx.rotate(by: layer.rotation.radians)
        ctx.scaleBy(x: layer.scale, y: layer.scale)

        let baseWidth: CGFloat = 200
        let baseHeight = baseWidth / layer.aspectRatio
        let drawRect = CGRect(
            x: -baseWidth / 2,
            y: -baseHeight / 2,
            width: baseWidth,
            height: baseHeight
        )
        layer.image.draw(in: drawRect)

        ctx.restoreGState()
    }

    private static func nsAlignment(from alignment: TextAlignment) -> NSTextAlignment {
        switch alignment {
        case .leading: return .left
        case .center: return .center
        case .trailing: return .right
        }
    }
}
