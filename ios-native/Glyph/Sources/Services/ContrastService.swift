import SwiftUI

/// WCAG 2.1 contrast-ratio calculator.
///
/// Use this to verify that text colours meet accessibility thresholds
/// before rendering them on a given background.
///
/// Levels:
/// - **AA** (normal text): ratio ≥ 4.5 : 1
/// - **AA Large** (18 pt / bold 14 pt): ratio ≥ 3.0 : 1
enum ContrastService {

    /// Returns the WCAG 2.1 contrast ratio between two colours.
    /// The result is in the range 1…21 where 21 is black-on-white.
    static func ratio(foreground: Color, background: Color) -> Double {
        let l1 = relativeLuminance(of: foreground)
        let l2 = relativeLuminance(of: background)
        let lighter = max(l1, l2)
        let darker  = min(l1, l2)
        return (lighter + 0.05) / (darker + 0.05)
    }

    /// `true` when the pair meets WCAG 2.1 Level AA for normal text (≥ 4.5).
    static func passesAA(foreground: Color, background: Color) -> Bool {
        ratio(foreground: foreground, background: background) >= 4.5
    }

    /// `true` when the pair meets WCAG 2.1 Level AA for large text (≥ 3.0).
    static func passesAALarge(foreground: Color, background: Color) -> Bool {
        ratio(foreground: foreground, background: background) >= 3.0
    }

    // MARK: - Private helpers

    /// Relative luminance per WCAG 2.1 §1.4.3.
    private static func relativeLuminance(of color: Color) -> Double {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(color).getRed(&r, green: &g, blue: &b, alpha: &a)
        return 0.2126 * linearize(r) + 0.7152 * linearize(g) + 0.0722 * linearize(b)
    }

    /// Converts a gamma-corrected sRGB channel to linear light.
    private static func linearize(_ channel: CGFloat) -> Double {
        let c = Double(channel)
        return c <= 0.04045 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
    }
}
