import Foundation

/// A font available in the app — either bundled or imported by the user.
struct FontEntry: Identifiable, Codable, Hashable {
    let id: UUID
    var displayName: String
    var familyName: String
    var filePath: String?
    var isBundled: Bool
    var dateAdded: Date

    init(
        id: UUID = UUID(),
        displayName: String,
        familyName: String,
        filePath: String? = nil,
        isBundled: Bool = false,
        dateAdded: Date = Date()
    ) {
        self.id = id
        self.displayName = displayName
        self.familyName = familyName
        self.filePath = filePath
        self.isBundled = isBundled
        self.dateAdded = dateAdded
    }

    /// The 5 bundled OFL fonts shipped with the app.
    static let bundled: [FontEntry] = [
        FontEntry(displayName: "Playfair Display", familyName: "Playfair Display", isBundled: true),
        FontEntry(displayName: "Space Grotesk", familyName: "Space Grotesk", isBundled: true),
        FontEntry(displayName: "Archivo Black", familyName: "Archivo Black", isBundled: true),
        FontEntry(displayName: "Caveat", familyName: "Caveat", isBundled: true),
        FontEntry(displayName: "DM Serif Display", familyName: "DM Serif Display", isBundled: true),
    ]
}
