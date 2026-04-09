import SwiftUI

struct ConfirmSheet: View {
    let title: String
    let message: String
    var confirmTitle: String = "Confirm"
    var isDestructive: Bool = false
    let onConfirm: () -> Void
    let onCancel: () -> Void
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        let tc = themeManager.colors

        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(tc.textPrimary)

                Text(message)
                    .font(.system(size: 14))
                    .foregroundStyle(tc.textSecondary)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 12) {
                Button(action: onCancel) {
                    Text("Cancel")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(tc.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(tc.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(tc.borderInactive, lineWidth: 1)
                        )
                }

                Button(action: onConfirm) {
                    Text(confirmTitle)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(isDestructive ? tc.destructive : tc.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding(24)
        .background(tc.modalBg)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 24)
    }
}
