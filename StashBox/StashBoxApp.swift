import SwiftUI

@main
struct StashBoxApp: App {
    @StateObject private var store = AssetStore()
    @StateObject private var themeManager = ThemeManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environmentObject(themeManager)
                .preferredColorScheme(themeManager.current.colorScheme)
        }
    }
}
