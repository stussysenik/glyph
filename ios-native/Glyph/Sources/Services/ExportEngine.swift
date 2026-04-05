import UIKit
import SwiftUI

/// Renders text overlays to a transparent PNG image.
enum ExportEngine {

    /// Render all overlays into a single transparent PNG.
    /// The image is sized to fit all overlays with padding.
    static func renderOverlays(_ overlays: [TextOverlay], canvasSize: CGSize) -> UIImage? {
        let format = UIGraphicsImageRendererFormat()
        format.opaque = false
        format.scale = 2.0 // 2x keeps PNG under 2MB for Instagram

        let renderer = UIGraphicsImageRenderer(size: canvasSize, format: format)
        return renderer.image { context in
            let ctx = context.cgContext

            for overlay in overlays {
                ctx.saveGState()

                // Move to overlay position (relative to canvas center)
                let centerX = canvasSize.width / 2 + overlay.position.width
                let centerY = canvasSize.height / 2 + overlay.position.height
                ctx.translateBy(x: centerX, y: centerY)
                ctx.rotate(by: overlay.rotation.radians)
                ctx.scaleBy(x: overlay.scale, y: overlay.scale)

                // Build attributed string
                let font = FontLoader.uiFont(family: overlay.fontFamily, size: overlay.fontSize)
                let uiColor = UIColor(overlay.textColor)

                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.alignment = nsAlignment(from: overlay.alignment)

                let attributes: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: uiColor,
                    .paragraphStyle: paragraphStyle,
                    .kern: overlay.letterSpacing,
                ]

                let attrString = NSAttributedString(string: overlay.text, attributes: attributes)
                let textSize = attrString.boundingRect(
                    with: CGSize(width: canvasSize.width, height: .greatestFiniteMagnitude),
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    context: nil
                ).size

                // Draw centered at origin (we already translated to position)
                let drawRect = CGRect(
                    x: -textSize.width / 2,
                    y: -textSize.height / 2,
                    width: textSize.width,
                    height: textSize.height
                )
                attrString.draw(in: drawRect)

                ctx.restoreGState()
            }
        }
    }

    /// Render to PNG Data.
    static func renderToPNG(_ overlays: [TextOverlay], canvasSize: CGSize) -> Data? {
        renderOverlays(overlays, canvasSize: canvasSize)?.pngData()
    }

    private static func nsAlignment(from alignment: TextAlignment) -> NSTextAlignment {
        switch alignment {
        case .leading: return .left
        case .center: return .center
        case .trailing: return .right
        }
    }
}
