import UIKit
import CoreText

/// Registers fonts at runtime via CoreText.
enum FontLoader {

    /// Register a font from a file URL. Returns the PostScript name (font family) on success.
    static func register(url: URL) -> String? {
        var error: Unmanaged<CFError>?
        guard CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error) else {
            print("[FontLoader] Failed to register \(url.lastPathComponent): \(error?.takeRetainedValue().localizedDescription ?? "unknown")")
            return nil
        }
        return postScriptName(for: url)
    }

    /// Register a font from raw Data. Returns the PostScript name on success.
    static func register(data: Data) -> String? {
        guard let provider = CGDataProvider(data: data as CFData),
              let cgFont = CGFont(provider) else { return nil }

        var error: Unmanaged<CFError>?
        guard CTFontManagerRegisterGraphicsFont(cgFont, &error) else {
            print("[FontLoader] Failed to register font data: \(error?.takeRetainedValue().localizedDescription ?? "unknown")")
            return nil
        }
        return cgFont.postScriptName as String?
    }

    /// Validate that a font file can be loaded.
    static func validate(url: URL) -> Bool {
        guard let data = try? Data(contentsOf: url),
              let provider = CGDataProvider(data: data as CFData),
              CGFont(provider) != nil else { return false }
        return true
    }

    /// Create a UIFont from a registered family name.
    static func uiFont(family: String, size: CGFloat) -> UIFont {
        UIFont(name: family, size: size) ?? .systemFont(ofSize: size, weight: .regular)
    }

    // MARK: - Private

    private static func postScriptName(for url: URL) -> String? {
        guard let descriptors = CTFontManagerCreateFontDescriptorsFromURL(url as CFURL) as? [CTFontDescriptor],
              let first = descriptors.first else { return nil }
        return CTFontDescriptorCopyAttribute(first, kCTFontFamilyNameAttribute) as? String
    }
}
