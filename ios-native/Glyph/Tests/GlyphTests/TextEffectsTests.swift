import Testing
import UIKit
import SwiftUI
@testable import Glyph

/// Tests for the text-styling treatments (Slice 1): the TextEffects model,
/// the one-tap TextStyle presets, their CanvasViewModel mutators, and that
/// styled layers still render to a valid image.
@Suite("TextEffects")
@MainActor
struct TextEffectsTests {

    // MARK: - Model semantics

    @Test("A default TextEffects is plain")
    func defaultIsPlain() {
        #expect(TextEffects().isPlain)
    }

    @Test("A default TextLayer carries plain effects")
    func defaultLayerIsPlain() {
        #expect(TextLayer().effects.isPlain)
    }

    @Test("Plain style is plain; every other style applies a visible treatment")
    func styleTreatments() {
        #expect(TextStyle.plain.effects.isPlain)
        for style in TextStyle.allCases where style != .plain {
            #expect(!style.effects.isPlain, "\(style.label) should apply a visible treatment")
        }
    }

    @Test("Each named style maps to its defining treatment")
    func styleMapping() {
        #expect(TextStyle.highlight.effects.highlightColor != nil)
        #expect(TextStyle.outline.effects.strokeWidth > 0)
        #expect(TextStyle.neon.effects.shadowRadius > 0)
        #expect(TextStyle.shadow.effects.shadowRadius > 0)
        // Neon glows evenly (no offset); drop shadow is offset.
        #expect(TextStyle.neon.effects.shadowOffset == .zero)
        #expect(TextStyle.shadow.effects.shadowOffset != .zero)
    }

    // MARK: - ViewModel mutators

    @Test("applyTextStyle replaces effects, preserves fill color, and is undoable")
    func applyStyleIsUndoable() {
        let vm = CanvasViewModel()
        vm.addTextLayer()
        let id = try! #require(vm.selectedLayerID)
        vm.updateColor(id: id, color: .red)

        vm.applyTextStyle(id: id, style: .outline)
        let styled = try! #require(vm.selectedTextLayer)
        #expect(styled.effects.strokeWidth > 0)
        #expect(CodableColor(styled.textColor) == CodableColor(.red), "Style must not change the fill color")
        #expect(vm.canUndo)
    }

    @Test("updateEffects sets arbitrary effects on the layer")
    func updateEffectsSets() {
        let vm = CanvasViewModel()
        vm.addTextLayer()
        let id = try! #require(vm.selectedLayerID)

        var fx = TextEffects()
        fx.highlightColor = .yellow
        vm.updateEffects(id: id, effects: fx)

        #expect(vm.selectedTextLayer?.effects.highlightColor != nil)
    }

    // MARK: - Rendering

    let canvasSize = CGSize(width: 390, height: 844)

    @Test("Styled text layers render to a non-nil image", arguments: TextStyle.allCases)
    func renderStyledLayer(style: TextStyle) {
        var layer = TextLayer()
        layer.text = "Styled"
        layer.effects = style.effects

        let image = ExportEngine.renderLayers([layer], background: nil, canvasSize: canvasSize)
        #expect(image != nil, "\(style.label) styled layer must render")
    }
}

extension CodableColor: Equatable {
    public static func == (lhs: CodableColor, rhs: CodableColor) -> Bool {
        abs(lhs.red - rhs.red) < 0.01 && abs(lhs.green - rhs.green) < 0.01 &&
        abs(lhs.blue - rhs.blue) < 0.01 && abs(lhs.alpha - rhs.alpha) < 0.01
    }
}
