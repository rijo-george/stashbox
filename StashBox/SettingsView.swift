import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: AssetStore
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showingThemePicker = false
    @State private var showingExportAll = false
    @State private var showingResetConfirm = false

    var body: some View {
        let tc = themeManager.colors

        NavigationStack {
            ZStack {
                tc.bg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Appearance
                        VStack(alignment: .leading, spacing: 10) {
                            sectionLabel("Appearance", tc: tc)

                            Button {
                                showingThemePicker = true
                            } label: {
                                settingsRow(
                                    icon: "paintpalette",
                                    title: "Theme",
                                    value: themeManager.current.displayName,
                                    tc: tc
                                )
                            }
                        }

                        // Notifications
                        VStack(alignment: .leading, spacing: 10) {
                            sectionLabel("Notifications", tc: tc)
                            ReminderSettingsView()
                        }

                        // Data
                        VStack(alignment: .leading, spacing: 10) {
                            sectionLabel("Data", tc: tc)

                            Button {
                                showingExportAll = true
                            } label: {
                                settingsRow(icon: "square.and.arrow.up", title: "Export All Data", value: "CSV", tc: tc)
                            }

                            let assetCount = store.data.assets.count
                            let docCount = store.data.documents.count
                            settingsRow(
                                icon: "cylinder",
                                title: "Storage",
                                value: "\(assetCount) assets, \(docCount) documents",
                                tc: tc
                            )
                        }

                        // About
                        VStack(alignment: .leading, spacing: 10) {
                            sectionLabel("About", tc: tc)
                            settingsRow(icon: "info.circle", title: "Version", value: "1.0.0", tc: tc)
                            settingsRow(icon: "lock.shield", title: "Privacy", value: "All data on-device + iCloud", tc: tc)
                        }

                        // Danger zone
                        VStack(alignment: .leading, spacing: 10) {
                            sectionLabel("Advanced", tc: tc)

                            Button {
                                showingResetConfirm = true
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "trash")
                                        .foregroundStyle(tc.destructive)
                                    Text("Reset All Data")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundStyle(tc.destructive)
                                    Spacer()
                                }
                                .padding(14)
                                .background(tc.destructive.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(tc.destructive.opacity(0.2), lineWidth: 1))
                            }
                        }
                    }
                    .padding(16)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingThemePicker) {
                ThemePickerView()
            }
            .sheet(isPresented: $showingExportAll) {
                ExportSheet(asset: nil)
            }
            .alert("Reset All Data?", isPresented: $showingResetConfirm) {
                Button("Reset", role: .destructive) {
                    store.data = StashBoxData()
                    store.save()
                    Haptic.fire(.warning)
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete all assets, warranties, and documents. This cannot be undone.")
            }
        }
    }

    private func sectionLabel(_ text: String, tc: ThemeColors) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(tc.textSecondary)
            .textCase(.uppercase)
    }

    private func settingsRow(icon: String, title: String, value: String, tc: ThemeColors) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundStyle(tc.accent)
                .frame(width: 24)
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(tc.textPrimary)
            Spacer()
            Text(value)
                .font(.system(size: 13))
                .foregroundStyle(tc.textSecondary)
            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(tc.textSecondary.opacity(0.5))
        }
        .padding(14)
        .background(tc.surface)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
