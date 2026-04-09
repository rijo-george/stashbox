import SwiftUI

struct StatusBadge: View {
    let urgency: ExpiryUrgency
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        let tc = themeManager.colors
        let badgeColor = urgency.color(from: tc)

        HStack(spacing: 4) {
            Image(systemName: iconName)
                .font(.system(size: 9, weight: .bold))
            Text(urgency.label)
                .font(.system(size: 11, weight: .semibold))
        }
        .foregroundStyle(badgeColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(badgeColor.opacity(0.15))
        .clipShape(Capsule())
    }

    private var iconName: String {
        switch urgency {
        case .expired: return "xmark.circle.fill"
        case .critical: return "exclamationmark.triangle.fill"
        case .warning: return "clock.fill"
        case .upcoming: return "clock"
        case .safe: return "checkmark.shield.fill"
        case .lifetime: return "infinity"
        case .noWarranty: return "minus.circle"
        }
    }
}
