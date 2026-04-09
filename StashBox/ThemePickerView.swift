import SwiftUI

struct ThemePickerView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let tc = themeManager.colors

        NavigationStack {
            ZStack {
                tc.bg.ignoresSafeArea()

                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 150), spacing: 12)
                    ], spacing: 12) {
                        ForEach(ThemeName.allCases) { theme in
                            Button {
                                themeManager.current = theme
                                Haptic.fire(.selectionChanged)
                            } label: {
                                themeCard(theme, isSelected: themeManager.current == theme, tc: tc)
                            }
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Theme")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(tc.accent)
                }
            }
        }
        .presentationDetents([.medium])
    }

    @ViewBuilder
    private func themeCard(_ theme: ThemeName, isSelected: Bool, tc: ThemeColors) -> some View {
        let colors = theme.colors

        VStack(spacing: 8) {
            // Mini preview
            HStack(spacing: 4) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(colors.accent)
                    .frame(height: 30)
                RoundedRectangle(cornerRadius: 3)
                    .fill(colors.accentSecondary)
                    .frame(height: 30)
            }
            .padding(8)
            .background(colors.bg)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // Status colors
            HStack(spacing: 3) {
                Circle().fill(colors.warrantyActive).frame(width: 8, height: 8)
                Circle().fill(colors.warrantyExpiring).frame(width: 8, height: 8)
                Circle().fill(colors.warrantyExpired).frame(width: 8, height: 8)
                Circle().fill(colors.warrantySafe).frame(width: 8, height: 8)
            }

            Text(theme.displayName)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(isSelected ? tc.accent : tc.textPrimary)
        }
        .padding(12)
        .background(tc.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? tc.accent : tc.borderInactive, lineWidth: isSelected ? 2 : 1)
        )
    }
}
