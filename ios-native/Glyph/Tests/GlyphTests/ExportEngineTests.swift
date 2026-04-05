import Testing
import UIKit
import SwiftUI
@testable import Glyph

/// Tests for ExportEngine image rendering.
/// All rendering calls happen on the main actor to avoid UIKit thread warnings.
@Suite("ExportEngine")
@MainActor
struct ExportEngineTests {

    let canvasSize = CGSize(width: 390, height: 844)

    // MARK: - Empty canvas

    @Test("Renders empty canvas to non-nil UIImage")
    func renderEmptyCanvas() {
        let image = ExportEngine.renderLayers(
            [],
            background: nil,
            canvasSize: canvasSize
        )
        #expect(image != nil, "renderLayers must return a UIImage even for an empty canvas")
    }

    @Test("Empty canvas PNG data is non-nil")
    func emptyCanvasPNG() {
        let data = ExportEngine.renderToPNG(
            [],
            background: nil,
            canvasSize: canvasSize
        )
        #expect(data != nil)
    }

    // MARK: - Canvas dimensions

    @Test("Rendered image matches requested canvas size")
    func renderedImageMatchesCanvasSize() throws {
        let image = try #require(
            ExportEngine.renderLayers([], background: nil, canvasSize: canvasSize),
            "renderLayers must return a non-nil UIImage"
        )
        // UIGraphicsImageRenderer uses scale 2, so pixel size = canvas * scale
        let expectedWidth  = canvasSize.width  * 2
        let expectedHeight = canvasSize.height * 2
        #expect(image.size.width  * image.scale == expectedWidth)
        #expect(image.size.height * image.scale == expectedHeight)
    }

    // MARK: - Text layer rendering

    @Test("Renders canvas with a single text layer to non-nil UIImage")
    func renderWithTextLayer() {
        var layer = TextLayer()
        layer.text      = "Hello Glyph"
        layer.fontSize  = 48
        layer.zIndex    = 0
        layer.isVisible = true

        let image = ExportEngine.renderLayers(
            [layer],
            background: nil,
            canvasSize: canvasSize
        )
        #expect(image != nil)
    }

    @Test("Hidden text layer still produces a valid image")
    func renderWithHiddenTextLayer() {
        var layer = TextLayer()
        layer.text      = "Hidden"
        layer.isVisible = false

        let image = ExportEngine.renderLayers(
            [layer],
            background: nil,
            canvasSize: canvasSize
        )
        #expect(image != nil, "Rendering should succeed even when all layers are hidden")
    }

    // MARK: - Multiple layers

    @Test("Renders multiple text layers in z-index order without crashing")
    func renderMultipleLayers() {
        var bottom = TextLayer()
        bottom.text   = "Bottom"
        bottom.zIndex = 0

        var top = TextLayer()
        top.text   = "Top"
        top.zIndex = 1

        let image = ExportEngine.renderLayers(
            [top, bottom],   // intentionally out-of-order to test z-sort
            background: nil,
            canvasSize: canvasSize
        )
        #expect(image != nil)
    }

    // MARK: - PNG output

    @Test("renderToPNG returns valid PNG data for a text layer")
    func renderToPNG() throws {
        var layer = TextLayer()
        layer.text = "PNG Test"

        let data = try #require(
            ExportEngine.renderToPNG([layer], background: nil, canvasSize: canvasSize),
            "renderToPNG must return non-nil data"
        )
        // PNG magic bytes: 0x89 0x50 0x4E 0x47
        let magic = [UInt8](data.prefix(4))
        #expect(magic == [0x89, 0x50, 0x4E, 0x47], "Output must be valid PNG data")
    }

    // MARK: - renderToData format tests

    @Test("renderToData with PNG format returns valid PNG data")
    func pngFormatMagicBytes() {
        let canvasSize = CGSize(width: 100, height: 100)
        guard let data = ExportEngine.renderToData([], background: nil, canvasSize: canvasSize, format: "png") else {
            Issue.record("renderToData returned nil for PNG")
            return
        }
        // PNG magic bytes: 0x89 0x50 0x4E 0x47
        let bytes = [UInt8](data.prefix(4))
        #expect(bytes == [0x89, 0x50, 0x4E, 0x47])
    }

    @Test("renderToData with JPEG format returns valid JPEG data")
    func jpegFormatMagicBytes() {
        let canvasSize = CGSize(width: 100, height: 100)
        // JPEG needs opaque image — use a background
        var layer = TextLayer()
        layer.text = "Test"
        guard let data = ExportEngine.renderToData([layer], background: nil, canvasSize: canvasSize, format: "jpeg", quality: 0.8) else {
            Issue.record("renderToData returned nil for JPEG")
            return
        }
        // JPEG magic bytes: 0xFF 0xD8
        let bytes = [UInt8](data.prefix(2))
        #expect(bytes == [0xFF, 0xD8])
    }

    @Test("JPEG quality 0.5 produces smaller data than 1.0")
    func jpegQualityAffectsSize() {
        let canvasSize = CGSize(width: 200, height: 200)
        var layer = TextLayer()
        layer.text = "Quality Test"
        layer.fontSize = 40

        guard let lowQ = ExportEngine.renderToData([layer], background: nil, canvasSize: canvasSize, format: "jpeg", quality: 0.5),
              let highQ = ExportEngine.renderToData([layer], background: nil, canvasSize: canvasSize, format: "jpeg", quality: 1.0) else {
            Issue.record("renderToData returned nil")
            return
        }
        #expect(lowQ.count < highQ.count)
    }
}
