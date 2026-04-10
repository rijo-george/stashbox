import SwiftUI

struct AnalyticsView: View {
    @EnvironmentObject var store: AssetStore
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        let tc = themeManager.colors
        let assets = store.data.activeAssets

        NavigationStack {
            ZStack {
                tc.bg.ignoresSafeArea()

                if assets.isEmpty {
                    EmptyStateView(
                        icon: "chart.bar",
                        title: "No Data Yet",
                        subtitle: "Add assets to see your analytics"
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            overviewCards(assets, tc: tc)
                            warrantyCoverage(assets, tc: tc)
                            valueByCategory(assets, tc: tc)
                            spendingTimeline(assets, tc: tc)
                            topBrands(assets, tc: tc)
                            disposalSummary(tc: tc)
                        }
                        .padding(16)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("Analytics")
        }
    }

    // MARK: - Overview Cards

    @ViewBuilder
    private func overviewCards(_ assets: [Asset], tc: ThemeColors) -> some View {
        let totalValue = assets.compactMap(\.purchasePrice).reduce(0, +)
        let totalServiceCost = assets.reduce(0) { $0 + $1.totalServiceCost }
        let totalSavings = assets.reduce(0) { $0 + $1.totalSavings }
        let totalCOO = assets.reduce(0) { $0 + $1.totalCostOfOwnership }

        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            metricCard(icon: "shippingbox.fill", label: "Total Assets", value: "\(assets.count)", color: tc.accent, tc: tc)
            metricCard(icon: "dollarsign.circle.fill", label: "Total Value", value: formatCurrency(totalValue), color: tc.accent, tc: tc)
            metricCard(icon: "wrench.fill", label: "Service Costs", value: formatCurrency(totalServiceCost), color: tc.warrantyExpiring, tc: tc)
            metricCard(icon: "leaf.fill", label: "Claim Savings", value: formatCurrency(totalSavings), color: tc.warrantyActive, tc: tc)
            metricCard(icon: "chart.line.uptrend.xyaxis", label: "Cost of Ownership", value: formatCurrency(totalCOO), color: tc.accentSecondary, tc: tc)
            metricCard(icon: "doc.text.fill", label: "Documents", value: "\(store.data.documents.count)", color: tc.categoryTint, tc: tc)
        }
    }

    private func metricCard(icon: String, label: String, value: String, color: Color, tc: ThemeColors) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(tc.textPrimary)
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(tc.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(tc.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(tc.cardBorder, lineWidth: 1))
    }

    // MARK: - Warranty Coverage

    @ViewBuilder
    private func warrantyCoverage(_ assets: [Asset], tc: ThemeColors) -> some View {
        let covered = assets.filter { !$0.warranties.isEmpty }
        let active = covered.filter {
            switch $0.expiryStatus {
            case .safe, .upcoming, .warning, .critical, .lifetime: return true
            default: return false
            }
        }
        let expired = covered.filter {
            if case .expired = $0.expiryStatus { return true }
            return false
        }
        let uncovered = assets.count - covered.count
        let coveragePercent = assets.isEmpty ? 0 : Int(Double(active.count) / Double(assets.count) * 100)

        VStack(alignment: .leading, spacing: 12) {
            Text("Warranty Coverage")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(tc.textPrimary)

            // Coverage bar
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("\(coveragePercent)% covered")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(coveragePercent > 70 ? tc.warrantyActive : coveragePercent > 30 ? tc.warrantyExpiring : tc.warrantyExpired)
                    Spacer()
                }

                GeometryReader { geo in
                    let w = geo.size.width
                    let activeW = assets.isEmpty ? 0 : w * CGFloat(active.count) / CGFloat(assets.count)
                    let expiredW = assets.isEmpty ? 0 : w * CGFloat(expired.count) / CGFloat(assets.count)

                    HStack(spacing: 2) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(tc.warrantyActive)
                            .frame(width: max(activeW, 0))
                        RoundedRectangle(cornerRadius: 4)
                            .fill(tc.warrantyExpired)
                            .frame(width: max(expiredW, 0))
                        RoundedRectangle(cornerRadius: 4)
                            .fill(tc.textSecondary.opacity(0.2))
                    }
                }
                .frame(height: 8)
                .clipShape(RoundedRectangle(cornerRadius: 4))

                HStack(spacing: 16) {
                    legendItem("Active (\(active.count))", color: tc.warrantyActive, tc: tc)
                    legendItem("Expired (\(expired.count))", color: tc.warrantyExpired, tc: tc)
                    legendItem("None (\(uncovered))", color: tc.textSecondary.opacity(0.4), tc: tc)
                }
            }
        }
        .padding(14)
        .background(tc.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(tc.cardBorder, lineWidth: 1))
    }

    private func legendItem(_ label: String, color: Color, tc: ThemeColors) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(tc.textSecondary)
        }
    }

    // MARK: - Value by Category

    @ViewBuilder
    private func valueByCategory(_ assets: [Asset], tc: ThemeColors) -> some View {
        let grouped = Dictionary(grouping: assets) { $0.category }
        let sorted = grouped.map { (category: $0.key, count: $0.value.count, value: $0.value.compactMap(\.purchasePrice).reduce(0, +)) }
            .sorted { $0.value > $1.value }

        if !sorted.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Value by Category")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(tc.textPrimary)

                let maxValue = sorted.map(\.value).max() ?? 1

                ForEach(sorted, id: \.category) { item in
                    HStack(spacing: 10) {
                        Image(systemName: item.category.icon)
                            .font(.system(size: 12))
                            .foregroundStyle(tc.categoryTint)
                            .frame(width: 20)

                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(item.category.displayName)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(tc.textPrimary)
                                Text("(\(item.count))")
                                    .font(.system(size: 10))
                                    .foregroundStyle(tc.textSecondary)
                                Spacer()
                                Text(formatCurrency(item.value))
                                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                    .foregroundStyle(tc.textPrimary)
                            }

                            GeometryReader { geo in
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(tc.accent.opacity(0.6))
                                    .frame(width: maxValue > 0 ? geo.size.width * CGFloat(item.value / maxValue) : 0)
                            }
                            .frame(height: 4)
                        }
                    }
                }
            }
            .padding(14)
            .background(tc.cardBg)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(tc.cardBorder, lineWidth: 1))
        }
    }

    // MARK: - Spending Timeline (by month)

    @ViewBuilder
    private func spendingTimeline(_ assets: [Asset], tc: ThemeColors) -> some View {
        let byMonth = Dictionary(grouping: assets) { asset -> String in
            guard let date = ISO8601Flexible.date(from: asset.purchaseDate) else { return "Unknown" }
            let df = DateFormatter()
            df.dateFormat = "MMM yyyy"
            return df.string(from: date)
        }
        let sorted = byMonth.map { (month: $0.key, spent: $0.value.compactMap(\.purchasePrice).reduce(0, +), count: $0.value.count) }
            .sorted { a, b in
                let dfParse = DateFormatter()
                dfParse.dateFormat = "MMM yyyy"
                let dateA = dfParse.date(from: a.month) ?? .distantPast
                let dateB = dfParse.date(from: b.month) ?? .distantPast
                return dateA > dateB
            }
            .prefix(12)

        if !sorted.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Spending Timeline")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(tc.textPrimary)

                let maxSpent = sorted.map(\.spent).max() ?? 1

                ForEach(Array(sorted), id: \.month) { item in
                    HStack(spacing: 10) {
                        Text(item.month)
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundStyle(tc.textSecondary)
                            .frame(width: 60, alignment: .leading)

                        GeometryReader { geo in
                            RoundedRectangle(cornerRadius: 3)
                                .fill(tc.accentSecondary.opacity(0.6))
                                .frame(width: maxSpent > 0 ? geo.size.width * CGFloat(item.spent / maxSpent) : 0)
                        }
                        .frame(height: 14)

                        Text(formatCurrency(item.spent))
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundStyle(tc.textPrimary)
                            .frame(width: 70, alignment: .trailing)
                    }
                }
            }
            .padding(14)
            .background(tc.cardBg)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(tc.cardBorder, lineWidth: 1))
        }
    }

    // MARK: - Top Brands

    @ViewBuilder
    private func topBrands(_ assets: [Asset], tc: ThemeColors) -> some View {
        let grouped = Dictionary(grouping: assets.filter { !$0.brand.isEmpty }) { $0.brand }
        let sorted = grouped.map { (brand: $0.key, count: $0.value.count, value: $0.value.compactMap(\.purchasePrice).reduce(0, +)) }
            .sorted { $0.value > $1.value }
            .prefix(8)

        if !sorted.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Top Brands")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(tc.textPrimary)

                ForEach(Array(sorted), id: \.brand) { item in
                    HStack {
                        Text(item.brand)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(tc.textPrimary)
                        Text("\(item.count) item\(item.count == 1 ? "" : "s")")
                            .font(.system(size: 11))
                            .foregroundStyle(tc.textSecondary)
                        Spacer()
                        Text(formatCurrency(item.value))
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundStyle(tc.accent)
                    }
                    .padding(.vertical, 2)
                }
            }
            .padding(14)
            .background(tc.cardBg)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(tc.cardBorder, lineWidth: 1))
        }
    }

    // MARK: - Disposal Summary

    @ViewBuilder
    private func disposalSummary(tc: ThemeColors) -> some View {
        let disposed = store.data.assets.filter { $0.disposal != nil }

        if !disposed.isEmpty {
            let totalRecovered = disposed.compactMap { $0.disposal?.amount }.reduce(0, +)
            let byType = Dictionary(grouping: disposed) { $0.disposal!.type }

            VStack(alignment: .leading, spacing: 12) {
                Text("Disposed Assets")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(tc.textPrimary)

                HStack {
                    Text("\(disposed.count) items disposed")
                        .font(.system(size: 13))
                        .foregroundStyle(tc.textSecondary)
                    Spacer()
                    if totalRecovered > 0 {
                        Text("\(formatCurrency(totalRecovered)) recovered")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(tc.warrantyActive)
                    }
                }

                HStack(spacing: 12) {
                    ForEach(DisposalType.allCases) { type in
                        if let items = byType[type] {
                            HStack(spacing: 4) {
                                Image(systemName: type.icon)
                                    .font(.system(size: 10))
                                Text("\(items.count)")
                                    .font(.system(size: 11, weight: .medium))
                            }
                            .foregroundStyle(tc.textSecondary)
                        }
                    }
                }
            }
            .padding(14)
            .background(tc.cardBg)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(tc.cardBorder, lineWidth: 1))
        }
    }

    // MARK: - Helpers

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = Locale.current.currency?.identifier ?? "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? String(format: "%.0f", amount)
    }
}
