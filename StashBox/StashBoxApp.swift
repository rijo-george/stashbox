import SwiftUI
import CoreSpotlight

@main
struct StashBoxApp: App {
    @StateObject private var store = AssetStore()
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var pendingImports = PendingImportManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environmentObject(themeManager)
                .environmentObject(pendingImports)
                .preferredColorScheme(themeManager.current.colorScheme)
                .onContinueUserActivity(CSSearchableItemActionType) { activity in
                    if let id = activity.userInfo?[CSSearchableItemActivityIdentifier] as? String {
                        NotificationCenter.default.post(name: .openAsset, object: id)
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                    pendingImports.checkForPending()
                }
                .onAppear {
                    pendingImports.checkForPending()
                }
        }
    }
}

// MARK: - Pending Import Manager

class PendingImportManager: ObservableObject {
    @Published var pendingFiles: [String] = []
    @Published var hasPending = false

    private var groupURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.rijo.stashbox")
    }

    func checkForPending() {
        guard let groupURL else { return }
        let listURL = groupURL.appendingPathComponent("pending_imports.json")
        guard let data = try? Data(contentsOf: listURL),
              let files = try? JSONDecoder().decode([String].self, from: data),
              !files.isEmpty
        else {
            hasPending = false
            pendingFiles = []
            return
        }
        pendingFiles = files
        hasPending = true
    }

    func pendingFileURL(for filename: String) -> URL? {
        groupURL?.appendingPathComponent("Pending").appendingPathComponent(filename)
    }

    func clearPending() {
        guard let groupURL else { return }
        let listURL = groupURL.appendingPathComponent("pending_imports.json")
        try? FileManager.default.removeItem(at: listURL)
        // Clean up pending files
        let pendingDir = groupURL.appendingPathComponent("Pending")
        try? FileManager.default.removeItem(at: pendingDir)
        pendingFiles = []
        hasPending = false
    }

    func clearFile(_ filename: String) {
        pendingFiles.removeAll { $0 == filename }
        if let url = pendingFileURL(for: filename) {
            try? FileManager.default.removeItem(at: url)
        }
        // Update the list
        guard let groupURL else { return }
        let listURL = groupURL.appendingPathComponent("pending_imports.json")
        if pendingFiles.isEmpty {
            try? FileManager.default.removeItem(at: listURL)
            hasPending = false
        } else if let data = try? JSONEncoder().encode(pendingFiles) {
            try? data.write(to: listURL, options: .atomic)
        }
    }
}

extension Notification.Name {
    static let openAsset = Notification.Name("openAsset")
}
