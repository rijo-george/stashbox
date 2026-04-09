import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        let tc = themeManager.colors

        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(tc.textSecondary.opacity(0.5))

            VStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(tc.textPrimary)

                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundStyle(tc.textSecondary)
                    .multilineTextAlignment(.center)
            }

            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(tc.accent)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(tc.accent.opacity(0.12))
                        .clipShape(Capsule())
                }
            }
        }
        .padding(40)
    }
}
