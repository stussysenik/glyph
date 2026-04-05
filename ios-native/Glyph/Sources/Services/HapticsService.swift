import UIKit
import Observation

/// Centralised haptic feedback coordinator.
/// Call these methods from any view or view model to trigger
/// semantically named haptics rather than constructing generators
/// inline — keeping feedback consistent and easy to adjust globally.
@Observable
@MainActor
final class HapticsService {
    private let light  = UIImpactFeedbackGenerator(style: .light)
    private let medium = UIImpactFeedbackGenerator(style: .medium)
    private let notif  = UINotificationFeedbackGenerator()
    private let select = UISelectionFeedbackGenerator()

    /// Fired when a layer snaps to an alignment guide.
    func snapToGuide()      { light.impactOccurred() }

    /// Fired when a layer's lock state is toggled.
    func lockToggle()       { medium.impactOccurred() }

    /// Fired when a layer is deleted.
    func delete()           { notif.notificationOccurred(.warning) }

    /// Fired when an export completes successfully.
    func exportSuccess()    { notif.notificationOccurred(.success) }

    /// Fired when a discrete selection changes (color swatch, alignment, etc.).
    func selectionChanged() { select.selectionChanged() }
}
