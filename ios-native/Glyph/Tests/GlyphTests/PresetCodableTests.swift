import Testing
import Foundation
@testable import Glyph

/// Tests that StylePreset and its supporting value types (CodableColor,
/// CodableAlignment) survive a JSON encode → decode round-trip intact.
@Suite("StylePreset Codable")
struct PresetCodableTests {

    let encoder = JSONEncoder()
    let decoder = JSONDecoder()

    // MARK: - Full StylePreset round-trip

    @Test("StylePreset survives JSON round-trip")
    func stylePresetRoundTrip() throws {
        let original = StylePreset(
            id: UUID(uuidString: "DEADBEEF-0000-0000-0000-000000000001")!,
            name: "Test Preset",
            fontFamily: "Archivo Black",
            fontSize: 48,
            textColor: CodableColor(r: 0.1, g: 0.5, b: 0.9, a: 1.0),
            letterSpacing: 2.5,
            alignment: .trailing,
            isBuiltIn: false
        )

        let data    = try encoder.encode(original)
        let decoded = try decoder.decode(StylePreset.self, from: data)

        #expect(decoded.id            == original.id)
        #expect(decoded.name          == original.name)
        #expect(decoded.fontFamily    == original.fontFamily)
        #expect(decoded.fontSize      == original.fontSize)
        #expect(decoded.letterSpacing == original.letterSpacing)
        #expect(decoded.isBuiltIn     == original.isBuiltIn)
        #expect(decoded.alignment     == original.alignment)
    }

    // MARK: - CodableColor round-trip

    @Test("CodableColor preserves RGBA components")
    func codableColorRoundTrip() throws {
        let color = CodableColor(r: 0.25, g: 0.50, b: 0.75, a: 0.9)
        let data    = try encoder.encode(color)
        let decoded = try decoder.decode(CodableColor.self, from: data)

        // Allow a tiny floating-point rounding margin
        #expect(abs(decoded.red   - color.red)   < 0.0001)
        #expect(abs(decoded.green - color.green) < 0.0001)
        #expect(abs(decoded.blue  - color.blue)  < 0.0001)
        #expect(abs(decoded.alpha - color.alpha) < 0.0001)
    }

    @Test("CodableColor defaults alpha to 1.0 when not specified")
    func codableColorDefaultAlpha() {
        let color = CodableColor(r: 0, g: 0, b: 0)
        #expect(color.alpha == 1.0)
    }

    // MARK: - CodableAlignment round-trip

    @Test("CodableAlignment encodes and decodes all cases", arguments: [
        CodableAlignment.leading,
        CodableAlignment.center,
        CodableAlignment.trailing,
    ])
    func codableAlignmentRoundTrip(alignment: CodableAlignment) throws {
        let data    = try encoder.encode(alignment)
        let decoded = try decoder.decode(CodableAlignment.self, from: data)
        #expect(decoded == alignment)
    }

    // MARK: - Built-in presets

    @Test("All built-in presets are encodable")
    func builtInsEncode() throws {
        for preset in StylePreset.builtIns {
            let data    = try encoder.encode(preset)
            let decoded = try decoder.decode(StylePreset.self, from: data)
            #expect(decoded.id == preset.id, "Built-in preset ID must survive round-trip")
            #expect(decoded.isBuiltIn == true)
        }
    }

    @Test("StylePreset array survives JSON round-trip")
    func presetArrayRoundTrip() throws {
        let presets  = StylePreset.builtIns
        let data     = try encoder.encode(presets)
        let decoded  = try decoder.decode([StylePreset].self, from: data)
        #expect(decoded.count == presets.count)
    }
}
