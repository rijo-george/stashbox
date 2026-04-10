import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var store: AssetStore
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var pendingImports: PendingImportManager
    @State private var showingAddSheet = false
    @State private var searchText = ""

    var body: some View {
        let tc = themeManager.colors

        NavigationStack {
            ZStack {
                tc.bg.ignoresSafeArea()

                if store.data.activeAssets.isEmpty {
                    EmptyStateView(
                        icon: "shippingbox",
                        title: "No Assets Yet",
                        subtitle: "Add your first purchase to start tracking warranties",
                        actionTitle: "Add Asset",
                        action: { showingAddSheet = true }
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            // Pending imports from Share Extension
                            if pendingImports.hasPending {
                                HStack(spacing: 10) {
                                    Image(systemName: "square.and.arrow.down.fill")
                                        .foregroundStyle(tc.accent)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("\(pendingImports.pendingFiles.count) shared file\(pendingImports.pendingFiles.count == 1 ? "" : "s") waiting")
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundStyle(tc.textPrimary)
                                        Text("Tap to import into StashBox")
                                            .font(.system(size: 11))
                                            .foregroundStyle(tc.textSecondary)
                                    }
                                    Spacer()
                                    Button {
                                        importPendingFiles()
                                    } label: {
                                        Text("Import")
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 6)
                                            .background(tc.accent)
                                            .clipShape(Capsule())
                                    }
                                }
                                .padding(12)
                                .background(tc.accent.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(tc.accent.opacity(0.2), lineWidth: 1))
                            }

                            // Needs Attention — the only section that matters
                            needsAttentionSection(tc: tc)

                            // All assets (compact)
                            allAssetsSection(tc: tc)
                        }
                        .padding(16)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("StashBox")
            .searchable(text: $searchText, prompt: "Search assets...")
            .navigationDestination(for: String.self) { assetID in
                if let asset = store.asset(byID: assetID) {
                    AssetDetailView(asset: asset)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(tc.accent)
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddAssetSheet()
            }
        }
    }

    // MARK: - Needs Attention

    @ViewBuilder
    private func needsAttentionSection(tc: ThemeColors) -> some View {
        let expired = attentionAssets.filter {
            if case .expired = $0.expiryStatus { return true }
            return false
        }
        let critical = attentionAssets.filter {
            if case .critical = $0.expiryStatus { return true }
            return false
        }
        let warning = attentionAssets.filter {
            if case .warning = $0.expiryStatus { return true }
            return false
        }

        let allAttention = expired + critical + warning

        if !allAttention.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(tc.warrantyExpiring)
                        .font(.system(size: 14))
                    Text("Needs Attention")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(tc.textPrimary)
                    Spacer()
                    Text("\(allAttention.count)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(tc.warrantyExpiring)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(tc.warrantyExpiring.opacity(0.15))
                        .clipShape(Capsule())
                }

                ForEach(allAttention) { asset in
                    NavigationLink(value: asset.id) {
                        attentionRow(asset, tc: tc)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func attentionRow(_ asset: Asset, tc: ThemeColors) -> some View {
        HStack(spacing: 12) {
            // Urgency indicator
            Circle()
                .fill(asset.expiryStatus.color(from: tc))
                .frame(width: 10, height: 10)

            Image(systemName: asset.category.icon)
                .font(.system(size: 15))
                .foregroundStyle(tc.categoryTint)
                .frame(width: 32, height: 32)
                .background(tc.categoryTint.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(asset.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(tc.textPrimary)
                    .lineLimit(1)

                if let warranty = asset.primaryWarranty {
                    Text(warranty.isExpired ? "Warranty expired" : warrantyMessage(warranty))
                        .font(.system(size: 12))
                        .foregroundStyle(asset.expiryStatus.color(from: tc))
                }
            }

            Spacer()

            if let warranty = asset.primaryWarranty, let days = warranty.daysRemaining {
                Text(days <= 0 ? "Expired" : "\(days)d")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(asset.expiryStatus.color(from: tc))
            }
        }
        .padding(12)
        .background(tc.surface)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(asset.expiryStatus.color(from: tc).opacity(0.25), lineWidth: 1)
        )
    }

    private func warrantyMessage(_ warranty: Warranty) -> String {
        guard let days = warranty.daysRemaining else { return "" }
        if days <= 0 { return "Warranty expired" }
        if days == 1 { return "Expires tomorrow" }
        if days <= 7 { return "Expires in \(days) days" }
        if days <= 30 { return "Expires in \(days) days" }
        return "Expires in \(days) days"
    }

    // MARK: - All Assets

    @ViewBuilder
    private func allAssetsSection(tc: ThemeColors) -> some View {
        let assets = filteredAssets

        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("All Assets")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(tc.textPrimary)
                Spacer()
                Text("\(assets.count)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(tc.textSecondary)
            }

            if assets.isEmpty && !searchText.isEmpty {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(tc.textSecondary.opacity(0.5))
                    Text("No results for \"\(searchText)\"")
                        .font(.system(size: 13))
                        .foregroundStyle(tc.textSecondary)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(tc.surface)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                ForEach(assets) { asset in
                    NavigationLink(value: asset.id) {
                        compactRow(asset, tc: tc)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func compactRow(_ asset: Asset, tc: ThemeColors) -> some View {
        HStack(spacing: 10) {
            Image(systemName: asset.category.icon)
                .font(.system(size: 14))
                .foregroundStyle(tc.categoryTint)
                .frame(width: 30, height: 30)
                .background(tc.categoryTint.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 7))

            VStack(alignment: .leading, spacing: 1) {
                Text(asset.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(tc.textPrimary)
                    .lineLimit(1)
                if !asset.brand.isEmpty {
                    Text(asset.brand)
                        .font(.system(size: 11))
                        .foregroundStyle(tc.textSecondary)
                }
            }

            Spacer()

            StatusBadge(urgency: asset.expiryStatus)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(tc.surface)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Filtering

    private var attentionAssets: [Asset] {
        store.data.activeAssets.filter {
            switch $0.expiryStatus {
            case .expired, .critical, .warning: return true
            default: return false
            }
        }.sorted {
            ($0.latestExpiry ?? .distantFuture) < ($1.latestExpiry ?? .distantFuture)
        }
    }

    private func importPendingFiles() {
        for filename in pendingImports.pendingFiles {
            guard let url = pendingImports.pendingFileURL(for: filename) else { continue }
            let ext = (filename as NSString).pathExtension.lowercased()
            if ext == "pdf" {
                if let meta = DocumentStore.shared.saveFile(from: url, type: .receipt) {
                    store.addDocumentMetadata(meta)
                    // Create a placeholder asset
                    let asset = Asset(name: "Imported Document", documentIDs: [meta.id])
                    store.addAsset(asset)
                }
            } else {
                // Image
                if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                    let meta = DocumentStore.shared.saveImage(image, type: .receipt)
                    store.addDocumentMetadata(meta)
                    let asset = Asset(name: "Imported Receipt", documentIDs: [meta.id])
                    store.addAsset(asset)
                }
            }
        }
        pendingImports.clearPending()
        Haptic.fire(.success)
    }

    private var filteredAssets: [Asset] {
        var result = store.data.activeAssets
        if !searchText.isEmpty {
            let q = searchText.lowercased()
            result = result.filter {
                $0.name.lowercased().contains(q) ||
                $0.brand.lowercased().contains(q) ||
                $0.retailer.lowercased().contains(q) ||
                $0.category.displayName.lowercased().contains(q)
            }
        }
        return result.sorted {
            (ISO8601Flexible.date(from: $0.createdAt) ?? .distantPast) >
            (ISO8601Flexible.date(from: $1.createdAt) ?? .distantPast)
        }
    }
}
