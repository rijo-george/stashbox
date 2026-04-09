import SwiftUI

struct TimelineView: View {
    let asset: Asset
    @EnvironmentObject var themeManager: ThemeManager

    private var events: [TimelineEvent] {
        var result: [TimelineEvent] = []

        // Purchase event
        result.append(TimelineEvent(
            date: asset.purchaseDate,
            icon: "bag.fill",
            title: "Purchased",
            subtitle: asset.retailer.isEmpty ? nil : "from \(asset.retailer)",
            color: .purchase
        ))

        // Warranty starts
        for w in asset.warranties {
            result.append(TimelineEvent(
                date: w.startDate,
                icon: "shield.checkered",
                title: "\(w.name) started",
                subtitle: w.isLifetime ? "Lifetime coverage" : nil,
                color: .warranty
            ))
        }

        // Service records
        for s in asset.serviceRecords {
            result.append(TimelineEvent(
                date: s.date,
                icon: s.type.icon,
                title: s.description.isEmpty ? s.type.displayName : s.description,
                subtitle: s.servicer.isEmpty ? nil : s.servicer,
                color: s.coveredByWarranty ? .warranty : .service
            ))
        }

        // Warranty claims
        for w in asset.warranties {
            for c in w.claims {
                result.append(TimelineEvent(
                    date: c.date,
                    icon: "checkmark.seal.fill",
                    title: "Claim: \(c.description)",
                    subtitle: c.outcome,
                    color: .claim
                ))
            }
        }

        // Warranty ends
        for w in asset.warranties where !w.isLifetime {
            if let end = w.endDate {
                result.append(TimelineEvent(
                    date: end,
                    icon: w.isExpired ? "xmark.shield" : "clock",
                    title: "\(w.name) \(w.isExpired ? "expired" : "expires")",
                    subtitle: nil,
                    color: w.isExpired ? .expired : .warning
                ))
            }
        }

        return result.sorted {
            (ISO8601Flexible.date(from: $0.date) ?? .distantPast) <
            (ISO8601Flexible.date(from: $1.date) ?? .distantPast)
        }
    }

    var body: some View {
        let tc = themeManager.colors

        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(events.enumerated()), id: \.offset) { index, event in
                HStack(alignment: .top, spacing: 12) {
                    // Timeline line + dot
                    VStack(spacing: 0) {
                        if index > 0 {
                            Rectangle()
                                .fill(tc.borderInactive)
                                .frame(width: 2, height: 16)
                        } else {
                            Spacer().frame(height: 16)
                        }

                        Image(systemName: event.icon)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(event.color.resolve(tc))
                            .frame(width: 28, height: 28)
                            .background(event.color.resolve(tc).opacity(0.15))
                            .clipShape(Circle())

                        if index < events.count - 1 {
                            Rectangle()
                                .fill(tc.borderInactive)
                                .frame(width: 2)
                                .frame(maxHeight: .infinity)
                        }
                    }
                    .frame(width: 28)

                    // Event content
                    VStack(alignment: .leading, spacing: 2) {
                        Text(event.title)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(tc.textPrimary)

                        if let subtitle = event.subtitle {
                            Text(subtitle)
                                .font(.system(size: 11))
                                .foregroundStyle(tc.textSecondary)
                        }

                        Text(displayDate(event.date))
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundStyle(tc.textSecondary.opacity(0.7))
                    }
                    .padding(.vertical, 8)

                    Spacer()
                }
            }
        }
    }
}

// MARK: - Timeline Event

private struct TimelineEvent {
    let date: String
    let icon: String
    let title: String
    let subtitle: String?
    let color: EventColor
}

private enum EventColor {
    case purchase
    case warranty
    case service
    case claim
    case expired
    case warning

    func resolve(_ tc: ThemeColors) -> Color {
        switch self {
        case .purchase: return tc.accent
        case .warranty: return tc.warrantySafe
        case .service: return tc.accentSecondary
        case .claim: return tc.warrantyActive
        case .expired: return tc.warrantyExpired
        case .warning: return tc.warrantyExpiring
        }
    }
}
