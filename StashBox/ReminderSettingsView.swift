import SwiftUI

struct ReminderSettingsView: View {
    @EnvironmentObject var store: AssetStore
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject var notificationManager = NotificationManager.shared

    @State private var selectedDays: Set<Int> = []

    var body: some View {
        let tc = themeManager.colors

        VStack(alignment: .leading, spacing: 20) {
            // Authorization status
            HStack {
                Image(systemName: notificationManager.isAuthorized ? "bell.badge.fill" : "bell.slash")
                    .foregroundStyle(notificationManager.isAuthorized ? tc.warrantyActive : tc.warrantyExpired)
                Text(notificationManager.isAuthorized ? "Notifications Enabled" : "Notifications Disabled")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(tc.textPrimary)
                Spacer()
                if !notificationManager.isAuthorized {
                    Button("Enable") {
                        notificationManager.requestAuthorization()
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(tc.accent)
                }
            }
            .padding(12)
            .background(tc.surface)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            // Default reminder days
            VStack(alignment: .leading, spacing: 10) {
                Text("Default Reminder Schedule")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(tc.textPrimary)

                Text("Notify before warranty expiry:")
                    .font(.system(size: 13))
                    .foregroundStyle(tc.textSecondary)

                HStack(spacing: 10) {
                    ForEach([90, 30, 7, 1], id: \.self) { days in
                        Button {
                            if selectedDays.contains(days) {
                                selectedDays.remove(days)
                            } else {
                                selectedDays.insert(days)
                            }
                            saveDefaults()
                            Haptic.fire(.selectionChanged)
                        } label: {
                            Text("\(days) day\(days == 1 ? "" : "s")")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(selectedDays.contains(days) ? tc.accent : tc.textSecondary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(selectedDays.contains(days) ? tc.accent.opacity(0.12) : tc.surface)
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule().stroke(
                                        selectedDays.contains(days) ? tc.accent.opacity(0.3) : tc.borderInactive,
                                        lineWidth: 1
                                    )
                                )
                        }
                    }
                }
            }
        }
        .onAppear {
            selectedDays = Set(store.data.settings.defaultReminderDays)
        }
    }

    private func saveDefaults() {
        var settings = store.data.settings
        settings.defaultReminderDays = Array(selectedDays).sorted(by: >)
        store.updateSettings(settings)
    }
}
