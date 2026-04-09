import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: AssetStore
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.horizontalSizeClass) private var sizeClass
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        let tc = themeManager.colors

        Group {
            if sizeClass == .regular {
                iPadLayout
            } else {
                iPhoneLayout
            }
        }
        .tint(tc.accent)
        .fullScreenCover(isPresented: Binding(
            get: { !hasCompletedOnboarding },
            set: { if !$0 { hasCompletedOnboarding = true } }
        )) {
            OnboardingView {
                hasCompletedOnboarding = true
            }
        }
    }

    // MARK: - iPhone (TabView)

    private var iPhoneLayout: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "square.grid.2x2")
                }

            AssetListView()
                .tabItem {
                    Label("Assets", systemImage: "shippingbox")
                }

            ScanReceiptSheet()
                .tabItem {
                    Label("Scan", systemImage: "camera")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
    }

    // MARK: - iPad (NavigationSplitView)

    @State private var selectedCategory: AssetCategory? = nil
    @State private var selectedAssetID: String? = nil

    private var iPadLayout: some View {
        let tc = themeManager.colors

        return NavigationSplitView {
            List(selection: $selectedCategory) {
                Section("Categories") {
                    ForEach(AssetCategory.allCases) { category in
                        let count = store.data.activeAssets.filter { $0.category == category }.count
                        if count > 0 {
                            Label {
                                HStack {
                                    Text(category.displayName)
                                    Spacer()
                                    Text("\(count)")
                                        .foregroundStyle(tc.textSecondary)
                                }
                            } icon: {
                                Image(systemName: category.icon)
                                    .foregroundStyle(tc.categoryTint)
                            }
                            .tag(category)
                        }
                    }
                }

                Section {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Label("Settings", systemImage: "gearshape")
                    }
                }
            }
            .navigationTitle("StashBox")
            .listStyle(.sidebar)
        } content: {
            AssetListView()
        } detail: {
            if let assetID = selectedAssetID, let asset = store.asset(byID: assetID) {
                AssetDetailView(asset: asset)
            } else {
                EmptyStateView(
                    icon: "shippingbox",
                    title: "Select an Asset",
                    subtitle: "Choose an asset from the list to view its details"
                )
            }
        }
    }
}
