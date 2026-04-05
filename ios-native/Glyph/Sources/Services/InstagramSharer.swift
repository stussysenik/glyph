import UIKit

/// Shares sticker images to Instagram Stories via UIPasteboard + URL scheme.
enum InstagramSharer {

    /// Whether Instagram is installed and can receive Stories.
    static var isAvailable: Bool {
        guard let url = URL(string: "instagram-stories://share") else { return false }
        return UIApplication.shared.canOpenURL(url)
    }

    /// Share a transparent PNG sticker to Instagram Stories.
    @MainActor
    static func shareSticker(_ image: UIImage) async -> Bool {
        guard let pngData = image.pngData(),
              let url = URL(string: "instagram-stories://share") else { return false }

        guard UIApplication.shared.canOpenURL(url) else { return false }

        let items: [[String: Any]] = [[
            "com.instagram.sharedSticker.stickerImage": pngData,
            "com.instagram.sharedSticker.backgroundTopColor": "#1A1A1A",
            "com.instagram.sharedSticker.backgroundBottomColor": "#1A1A1A",
        ]]

        UIPasteboard.general.setItems(items, options: [
            .expirationDate: Date().addingTimeInterval(300),
        ])

        return await UIApplication.shared.open(url)
    }

    /// Save image to the Photos library.
    static func saveToPhotos(_ image: UIImage) async -> Bool {
        await withCheckedContinuation { continuation in
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            // UIImageWriteToSavedPhotosAlbum doesn't have a great async API,
            // but it reliably saves. Give it a moment.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                continuation.resume(returning: true)
            }
        }
    }

    /// Copy image to system clipboard.
    static func copyToClipboard(_ image: UIImage) {
        UIPasteboard.general.image = image
    }
}
