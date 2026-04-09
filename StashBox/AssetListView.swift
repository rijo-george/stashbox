import SwiftUI

struct AssetListView: View {
    @EnvironmentObject var store: AssetStore
    @EnvironmentObject var themeManager: ThemeManager
    @State private var searchText = ""
    @State private var sortOption: SortOption = .purchaseDate
    @State private var filterOption: FilterOption = .all
    @State private var showingAddSheet = false
    @State private var showingScanSheet = false

    var body: some View {
        let tc = themeManager.colors

        NavigationStack {
            ZStack {
                tc.bg.ignoresSafeArea()

                if filteredAssets.isEmpty {
                    EmptyStateView(
                        icon: searchText.isEmpty ? "shippingbox" : "magnifyingglass",
                        title: searchText.isEmpty ? "No Assets Yet" : "No Results",
                        subtitle: searchText.isEmpty
                            ? "Add your first asset to start tracking warranties"
                            : "Try a different search term",
                        actionTitle: searchText.isEmpty ? "Add Asset" : nil,
                        action: searchText.isEmpty ? { showingAddSheet = true } : nil
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            // Filter chips
                            filterChips(tc: tc)

                            ForEach(filteredAssets) { asset in
                                NavigationLink(value: asset.id) {
                                    AssetRowView(asset: asset)
                                }
                                .buttonStyle(.plain)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        withAnimation {
                                            store.deleteAsset(asset.id)
                                        }
                                        Haptic.fire(.warning)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                                .swipeActions(edge: .leading) {
                                    Button {
                                        withAnimation {
                                            if asset.isArchived {
                                                store.unarchiveAsset(asset.id)
                                            } else {
                                                store.archiveAsset(asset.id)
                                            }
                                        }
                                        Haptic.fire(.success)
                                    } label: {
                                        Label(asset.isArchived ? "Unarchive" : "Archive",
                                              systemImage: asset.isArchived ? "tray.and.arrow.up" : "archivebox")
                                    }
                                    .tint(.orange)
                                }
                                .contextMenu {
                                    Button {
                                        store.archiveAsset(asset.id)
                                        Haptic.fire(.success)
                                    } label: {
                                        Label(asset.isArchived ? "Unarchive" : "Archive",
                                              systemImage: asset.isArchived ? "tray.and.arrow.up" : "archivebox")
                                    }
                                    Button(role: .destructive) {
                                        store.deleteAsset(asset.id)
                                        Haptic.fire(.warning)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationTitle("Assets")
            .searchable(text: $searchText, prompt: "Search assets...")
            .navigationDestination(for: String.self) { assetID in
                if let asset = store.asset(byID: assetID) {
                    AssetDetailView(asset: asset)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Section("Sort By") {
                            ForEach(SortOption.allCases) { option in
                                Button {
                                    sortOption = option
                                } label: {
                                    Label(option.displayName, systemImage: option.icon)
                                    if sortOption == option {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                            .foregroundStyle(tc.accent)
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            showingAddSheet = true
                        } label: {
                            Label("Add Manually", systemImage: "plus.circle")
                        }
                        Button {
                            showingScanSheet = true
                        } label: {
                            Label("Scan Receipt", systemImage: "camera")
                        }
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(tc.accent)
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddAssetSheet()
            }
            .sheet(isPresented: $showingScanSheet) {
                ScanReceiptSheet()
            }
        }
    }

    // MARK: - Filter chips

    @ViewBuilder
    private func filterChips(tc: ThemeColors) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chipButton("All", filter: .all, tc: tc)
                chipButton("Active", filter: .active, tc: tc)
                chipButton("Expiring", filter: .expiringWithin(days: 30), tc: tc)
                chipButton("Expired", filter: .expired, tc: tc)
                chipButton("Archived", filter: .archived, tc: tc)
            }
            .padding(.horizontal, 4)
        }
        .padding(.bottom, 4)
    }

    private func chipButton(_ title: String, filter: FilterOption, tc: ThemeColors) -> some View {
        let isSelected = filterOption == filter
        return Button {
            filterOption = filter
            Haptic.fire(.selectionChanged)
        } label: {
            Text(title)
                .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? tc.accent : tc.textSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isSelected ? tc.accent.opacity(0.12) : tc.surface)
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(isSelected ? tc.accent.opacity(0.3) : tc.borderInactive, lineWidth: 1)
                )
        }
    }

    // MARK: - Filtering & sorting

    private var filteredAssets: [Asset] {
        var result = store.data.assets

        // Apply filter
        switch filterOption {
        case .all:
            result = result.filter { !$0.isArchived }
        case .active:
            result = result.filter { !$0.isArchived && !$0.warranties.isEmpty }
        case .category(let cat):
            result = result.filter { $0.category == cat && !$0.isArchived }
        case .expiringWithin(let days):
            result = result.filter { asset in
                guard !asset.isArchived else { return false }
                switch asset.expiryStatus {
                case .critical, .warning: return true
                case .upcoming(let d): return d <= days
                default: return false
                }
            }
        case .expired:
            result = result.filter {
                if case .expired = $0.expiryStatus { return true }
                return false
            }
        case .archived:
            result = result.filter { $0.isArchived }
        }

        // Apply search
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter {
                $0.name.lowercased().contains(query) ||
                $0.brand.lowercased().contains(query) ||
                $0.retailer.lowercased().contains(query) ||
                $0.category.displayName.lowercased().contains(query) ||
                $0.tags.contains { $0.lowercased().contains(query) }
            }
        }

        // Apply sort
        switch sortOption {
        case .name:
            result.sort { $0.name.lowercased() < $1.name.lowercased() }
        case .purchaseDate:
            result.sort {
                (ISO8601Flexible.date(from: $0.purchaseDate) ?? .distantPast) >
                (ISO8601Flexible.date(from: $1.purchaseDate) ?? .distantPast)
            }
        case .expiryDate:
            result.sort {
                ($0.latestExpiry ?? .distantFuture) < ($1.latestExpiry ?? .distantFuture)
            }
        case .category:
            result.sort { $0.category.displayName < $1.category.displayName }
        case .price:
            result.sort { ($0.purchasePrice ?? 0) > ($1.purchasePrice ?? 0) }
        }

        return result
    }
}
