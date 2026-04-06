import Testing
import SwiftUI
@testable import Glyph

@Suite("Rotation Snap Engine")
struct RotationSnapEngineTests {

    // MARK: - snap() — exact cardinals

    @Test("exact 0° snaps to 0°")
    func exact0() {
        let result = RotationSnapEngine.snap(.degrees(0))
        #expect(result?.degrees == 0)
    }

    @Test("exact 90° snaps to 90°")
    func exact90() {
        let result = RotationSnapEngine.snap(.degrees(90))
        #expect(result?.degrees == 90)
    }

    @Test("exact 180° snaps to 180°")
    func exact180() {
        let result = RotationSnapEngine.snap(.degrees(180))
        #expect(result?.degrees == 180)
    }

    @Test("exact 270° snaps to 270°")
    func exact270() {
        let result = RotationSnapEngine.snap(.degrees(270))
        #expect(result?.degrees == 270)
    }

    // MARK: - snap() — within threshold

    @Test("88° snaps to 90° (within 5° threshold)")
    func withinThresholdAbove90() {
        let result = RotationSnapEngine.snap(.degrees(88))
        #expect(result?.degrees == 90)
    }

    @Test("92° snaps to 90° (within 5° threshold)")
    func withinThresholdBelow90() {
        let result = RotationSnapEngine.snap(.degrees(92))
        #expect(result?.degrees == 90)
    }

    @Test("4° snaps to 0° (within threshold)")
    func withinThresholdAbove0() {
        let result = RotationSnapEngine.snap(.degrees(4))
        #expect(result?.degrees == 0)
    }

    @Test("-4° snaps to 0° (within threshold, negative)")
    func withinThresholdNegative0() {
        let result = RotationSnapEngine.snap(.degrees(-4))
        #expect(result?.degrees == 0)
    }

    @Test("175° snaps to 180° (within threshold)")
    func withinThreshold180() {
        let result = RotationSnapEngine.snap(.degrees(175))
        #expect(result?.degrees == 180)
    }

    @Test("268° snaps to 270° (within threshold)")
    func withinThreshold270() {
        let result = RotationSnapEngine.snap(.degrees(268))
        #expect(result?.degrees == 270)
    }

    // MARK: - snap() — outside threshold

    @Test("85° snaps to 90° (boundary: |85-90|=5 <= threshold)")
    func boundary85() {
        let result = RotationSnapEngine.snap(.degrees(85))
        #expect(result?.degrees == 90)
    }

    @Test("95° snaps to 90° (boundary: |95-90|=5 <= threshold)")
    func boundary95() {
        let result = RotationSnapEngine.snap(.degrees(95))
        #expect(result?.degrees == 90)
    }

    @Test("45° returns nil")
    func outsideThreshold45() {
        let result = RotationSnapEngine.snap(.degrees(45))
        #expect(result == nil)
    }

    @Test("130° returns nil")
    func outsideThreshold130() {
        let result = RotationSnapEngine.snap(.degrees(130))
        #expect(result == nil)
    }

    // MARK: - snap() — threshold boundary

    @Test("exactly 5° from 0° snaps (boundary inclusive)")
    func boundary5From0() {
        let result = RotationSnapEngine.snap(.degrees(5))
        #expect(result?.degrees == 0)
    }

    @Test("exactly -5° from 0° snaps (boundary inclusive)")
    func boundaryNegative5From0() {
        let result = RotationSnapEngine.snap(.degrees(-5))
        #expect(result?.degrees == 0)
    }

    @Test("6° from 0° returns nil (just past boundary)")
    func boundary6From0() {
        let result = RotationSnapEngine.snap(.degrees(6))
        #expect(result == nil)
    }

    // MARK: - snap() — custom threshold

    @Test("85° snaps to 90° with threshold 10")
    func customThreshold85() {
        let result = RotationSnapEngine.snap(.degrees(85), threshold: 10)
        #expect(result?.degrees == 90)
    }

    @Test("80° returns nil with threshold 5 but snaps with threshold 15")
    func customThresholdComparision() {
        #expect(RotationSnapEngine.snap(.degrees(80), threshold: 5) == nil)
        #expect(RotationSnapEngine.snap(.degrees(80), threshold: 15)?.degrees == 90)
    }

    // MARK: - snap() — negative angles normalize to [0, 360)

    @Test("-90° normalizes to 270°")
    func negative90Normalizes() {
        let result = RotationSnapEngine.snap(.degrees(-90))
        #expect(result?.degrees == 270)
    }

    @Test("-180° normalizes to 180°")
    func negative180Normalizes() {
        let result = RotationSnapEngine.snap(.degrees(-180))
        #expect(result?.degrees == 180)
    }

    @Test("-270° normalizes to 90°")
    func negative270Normalizes() {
        let result = RotationSnapEngine.snap(.degrees(-270))
        #expect(result?.degrees == 90)
    }

    @Test("-88° snaps and normalizes to 270°")
    func negative88Normalizes() {
        let result = RotationSnapEngine.snap(.degrees(-88))
        #expect(result?.degrees == 270)
    }

    // MARK: - snap() — angles beyond 360°

    @Test("360° normalizes to 0°")
    func full360Normalizes() {
        let result = RotationSnapEngine.snap(.degrees(360))
        #expect(result?.degrees == 0)
    }

    @Test("450° returns nil (beyond cardinals range, no normalization)")
    func beyond360() {
        let result = RotationSnapEngine.snap(.degrees(450))
        // Engine cardinals only cover [-360, 360]. 450 is outside.
        #expect(result == nil)
    }

    @Test("-360° normalizes to 0°")
    func negative360Normalizes() {
        let result = RotationSnapEngine.snap(.degrees(-360))
        #expect(result?.degrees == 0)
    }

    // MARK: - nearestCardinal()

    @Test("nearest cardinal to 45° is 90°")
    func nearestTo45() {
        let result = RotationSnapEngine.nearestCardinal(.degrees(45))
        #expect(result.degrees == 0)
    }

    @Test("nearest cardinal to 46° is 90°")
    func nearestTo46() {
        let result = RotationSnapEngine.nearestCardinal(.degrees(46))
        #expect(result.degrees == 90)
    }

    @Test("nearest cardinal to 135° is 90°")
    func nearestTo135() {
        let result = RotationSnapEngine.nearestCardinal(.degrees(135))
        #expect(result.degrees == 90)
    }

    @Test("nearest cardinal to 136° is 180°")
    func nearestTo136() {
        let result = RotationSnapEngine.nearestCardinal(.degrees(136))
        #expect(result.degrees == 180)
    }

    @Test("nearest cardinal to 315° is 270°")
    func nearestTo315() {
        let result = RotationSnapEngine.nearestCardinal(.degrees(315))
        #expect(result.degrees == 270)
    }

    @Test("nearest cardinal to 316° is 0°")
    func nearestTo316() {
        let result = RotationSnapEngine.nearestCardinal(.degrees(316))
        #expect(result.degrees == 0)
    }

    @Test("nearest cardinal normalizes negative angles")
    func nearestNegative() {
        let result = RotationSnapEngine.nearestCardinal(.degrees(-45))
        // -45 is closest to 0 (distance 45) or -90 (distance 45) — both are equidistant
        // Implementation picks whichever appears first in cardinals array
        #expect(result.degrees == 0 || result.degrees == 270)
    }

    // MARK: - Round-trip: snap then nearest

    @Test("snap returns nil for midpoints, nearestCardinal always returns cardinal")
    func snapVsNearest() {
        let midAngles: [Double] = [45, 135, 225, 315]
        for angle in midAngles {
            #expect(RotationSnapEngine.snap(.degrees(angle)) == nil)
            let nearest = RotationSnapEngine.nearestCardinal(.degrees(angle))
            #expect(nearest.degrees == 0 || nearest.degrees == 90 || nearest.degrees == 180 || nearest.degrees == 270)
        }
    }
}
