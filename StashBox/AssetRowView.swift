import SwiftUI

struct AssetRowView: View {
    let asset: Asset
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        let tc = themeManager.colors

        HStack(spacing: 12) {
            // Category icon
            Image(systemName: asset.category.icon)
                .font(.system(size: 18))
                .foregroundStyle(tc.categoryTint)
                .frame(width: 40, height: 40)
                .background(tc.categoryTint.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            // Info
            VStack(alignment: .leading, spacing: 3) {
                Text(asset.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(tc.textPrimary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    if !asset.brand.isEmpty {
                        Text(asset.brand)
                            .font(.system(size: 12))
                            .foregroundStyle(tc.textSecondary)
                    }
                    if !asset.brand.isEmpty && !asset.retailer.isEmpty {
                        Text("·")
                            .foregroundStyle(tc.textSecondary.opacity(0.5))
                    }
                    if !asset.retailer.isEmpty {
                        Text(asset.retailer)
                            .font(.system(size: 12))
                            .foregroundStyle(tc.textSecondary)
                    }
                }
            }

            Spacer()

            // Status
            VStack(alignment: .trailing, spacing: 4) {
                StatusBadge(urgency: asset.expiryStatus)

                if asset.purchasePrice != nil {
                    Text(asset.priceDisplay)
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(tc.textSecondary)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(tc.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
