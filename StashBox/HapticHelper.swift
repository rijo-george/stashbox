import UIKit

enum HapticStyle {
    case light
    case medium
    case heavy
    case success
    case warning
    case error
    case selectionChanged
}

enum Haptic {
    static func fire(_ style: HapticStyle) {
        switch style {
        case .light:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .medium:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .heavy:
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        case .success:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .warning:
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        case .error:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        case .selectionChanged:
            UISelectionFeedbackGenerator().selectionChanged()
        }
    }
}
