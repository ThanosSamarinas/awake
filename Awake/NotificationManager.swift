import UserNotifications

final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()

    private static let sessionEndedCategory = "SESSION_ENDED"
    private static let restartAction = "RESTART_SESSION"

    var onRestartRequested: (() -> Void)?

    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    func requestAuthorization() {
        let restartAction = UNNotificationAction(
            identifier: Self.restartAction,
            title: "Restart",
            options: .foreground
        )
        let category = UNNotificationCategory(
            identifier: Self.sessionEndedCategory,
            actions: [restartAction],
            intentIdentifiers: []
        )
        UNUserNotificationCenter.current().setNotificationCategories([category])
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func postSessionEnded(durationLabel: String) {
        let content = UNMutableNotificationContent()
        content.title = "Session Ended"
        content.body = "Your \(durationLabel) session has completed."
        content.sound = .default
        content.categoryIdentifier = Self.sessionEndedCategory

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        if response.actionIdentifier == Self.restartAction {
            DispatchQueue.main.async { self.onRestartRequested?() }
        }
        completionHandler()
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
