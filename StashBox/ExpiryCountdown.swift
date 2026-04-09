import SwiftUI

struct ExpiryCountdown: View {
    let urgency: ExpiryUrgency
    var compact: Bool = false
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        let tc = themeManager.colors
        let color = urgency.color(from: tc)

        if compact {
            compactView(color: color)
        } else {
            fullView(color: color)
        }
    }

    @ViewBuilder
    private func fullView(color: Color) -> some View {
        VStack(spacing: 2) {
            Text(valueText)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(subtitleText)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(color.opacity(0.8))
        }
    }

    @ViewBuilder
    private func compactView(color: Color) -> some View {
        HStack(spacing: 4) {
            Text(valueText)
                .font(.system(size: 14, weight: .bold, design: .rounded))
            Text(subtitleText)
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundStyle(color)
    }

    private var valueText: String {
        switch urgency {
        case .expired: return "0"
        case .critical(let d), .warning(let d), .upcoming(let d), .safe(let d):
            return "\(d)"
        case .lifetime: return "\u{221E}"
        case .noWarranty: return "—"
        }
    }

    private var subtitleText: String {
        switch urgency {
        case .expired: return "expired"
        case .critical(let d), .warning(let d), .upcoming(let d), .safe(let d):
            return d == 1 ? "day left" : "days left"
        case .lifetime: return "lifetime"
        case .noWarranty: return "no warranty"
        }
    }
}
