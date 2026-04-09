import Foundation
import UserNotifications

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    @Published var isAuthorized = false

    init() {
        checkAuthorization()
        registerCategories()
    }

    func checkAuthorization() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }

    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            DispatchQueue.main.async {
                self.isAuthorized = granted
            }
        }
    }

    private func registerCategories() {
        let viewAction = UNNotificationAction(identifier: "VIEW_ASSET", title: "View Asset", options: .foreground)
        let dismissAction = UNNotificationAction(identifier: "DISMISS", title: "Dismiss", options: .destructive)
        let category = UNNotificationCategory(
            identifier: "WARRANTY_EXPIRY",
            actions: [viewAction, dismissAction],
            intentIdentifiers: []
        )
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }

    // MARK: - Schedule reminders for one asset

    func scheduleReminders(for asset: Asset) {
        let center = UNUserNotificationCenter.current()

        for warranty in asset.warranties {
            guard let endDateStr = warranty.endDate,
                  let endDate = ISO8601Flexible.date(from: endDateStr),
                  endDate > Date() else { continue }

            for daysBefore in warranty.reminderDays {
                guard let triggerDate = Calendar.current.date(byAdding: .day, value: -daysBefore, to: endDate),
                      triggerDate > Date() else { continue }

                let identifier = "stashbox-\(asset.id)-\(warranty.id)-\(daysBefore)"

                let content = UNMutableNotificationContent()
                content.title = "Warranty Expiring Soon"
                content.body = "\(asset.name) — \(warranty.name) expires in \(daysBefore) day\(daysBefore == 1 ? "" : "s")"
                content.sound = .default
                content.categoryIdentifier = "WARRANTY_EXPIRY"
                content.userInfo = ["assetID": asset.id, "warrantyID": warranty.id]

                var fireComponents = Calendar.current.dateComponents([.year, .month, .day], from: triggerDate)
                fireComponents.hour = 9
                fireComponents.minute = 0

                let trigger = UNCalendarNotificationTrigger(dateMatching: fireComponents, repeats: false)
                let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
                center.add(request)
            }
        }
    }

    // MARK: - Cancel reminders for an asset

    func cancelReminders(for assetID: String) {
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { requests in
            let ids = requests
                .filter { $0.identifier.hasPrefix("stashbox-\(assetID)-") }
                .map(\.identifier)
            center.removePendingNotificationRequests(withIdentifiers: ids)
        }
    }

    // MARK: - Reschedule all (after sync)

    func rescheduleAll(assets: [Asset]) {
        let center = UNUserNotificationCenter.current()
        // Remove all StashBox notifications
        center.getPendingNotificationRequests { requests in
            let ids = requests
                .filter { $0.identifier.hasPrefix("stashbox-") }
                .map(\.identifier)
            center.removePendingNotificationRequests(withIdentifiers: ids)

            // Reschedule for all active assets
            for asset in assets where !asset.isArchived {
                self.scheduleReminders(for: asset)
            }
        }

        // Handle 64-notification limit
        trimToLimit()
    }

    private func trimToLimit() {
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { requests in
            let stashboxRequests = requests.filter { $0.identifier.hasPrefix("stashbox-") }
            if stashboxRequests.count <= 60 { return }

            // Sort by trigger date, remove furthest-out
            let sorted = stashboxRequests.sorted { a, b in
                let dateA = (a.trigger as? UNCalendarNotificationTrigger)?.nextTriggerDate() ?? .distantFuture
                let dateB = (b.trigger as? UNCalendarNotificationTrigger)?.nextTriggerDate() ?? .distantFuture
                return dateA < dateB
            }

            let toRemove = sorted.suffix(from: 60).map(\.identifier)
            center.removePendingNotificationRequests(withIdentifiers: Array(toRemove))
        }
    }
}
