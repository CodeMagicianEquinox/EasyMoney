import Foundation
import UserNotifications

enum BudgetRules {
    static func defaultLimit(for category: String) -> Double {
        switch category.lowercased() {
        case "food": return 700
        case "transport": return 350
        case "entertainment": return 200
        case "shopping": return 500
        case "bills": return 800
        default: return 500
        }
    }
}

final class BudgetNotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = BudgetNotificationManager()

    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    func sendAlertIfNeeded(
        category: String,
        previousSpent: Double,
        currentSpent: Double,
        limit: Double,
        date: Date
    ) {
        guard limit > 0 else { return }

        let previousProgress = previousSpent / limit
        let currentProgress = currentSpent / limit
        let threshold: Int

        if previousProgress < 1, currentProgress >= 1 {
            threshold = 100
        } else if previousProgress < 0.8, currentProgress >= 0.8 {
            threshold = 80
        } else {
            return
        }

        let content = UNMutableNotificationContent()
        if threshold == 100 {
            content.title = "\(category) budget exceeded"
            let spentText = currentSpent.formatted(.currency(code: "USD"))
            let limitText = limit.formatted(.currency(code: "USD"))
            content.body = "You have spent \(spentText) of your \(limitText) budget."
        } else {
            content.title = "\(category) budget is almost reached"
            content.body = "You have used \(Int((currentProgress * 100).rounded()))% of your monthly budget."
        }
        content.sound = .default

        let month = Calendar.current.dateComponents([.year, .month], from: date)
        let monthKey = "\(month.year ?? 0)-\(month.month ?? 0)"
        let categoryKey = category.lowercased().replacingOccurrences(of: " ", with: "-")
        let request = UNNotificationRequest(
            identifier: "budget-\(categoryKey)-\(monthKey)-\(threshold)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
