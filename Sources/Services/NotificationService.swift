import AppKit
import Foundation
import UserNotifications

public final class NotificationService: NSObject, UNUserNotificationCenterDelegate {
    public static let shared = NotificationService()

    public override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    public func requestAuthorization() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("[macDisplayMagic] UserNotifications permission granted.")
            } else if let error = error {
                print("[macDisplayMagic] UserNotifications permission error: \(error.localizedDescription)")
            }
        }
    }

    public func sendZoomNotification(appName: String, screenName: String, category: DisplayCategory, action: ZoomAction) {
        let title = "macDisplayMagic"
        let body: String

        switch action {
        case .reset100:
            if category == .builtIn {
                body = "\(appName) moved to \(screenName) and now is in actual size"
            } else {
                body = "\(appName) moved to \(screenName) and reset to 100% zoom"
            }
        case .zoomIn(let steps):
            body = "\(appName) moved to \(screenName) (\(category.rawValue)) and now has zoomed in (+\(steps))"
        case .zoomOut(let steps):
            body = "\(appName) moved to \(screenName) (\(category.rawValue)) and now has zoomed out (-\(steps))"
        }

        sendNotification(title: title, body: body)
    }

    public func sendDisconnectNotification() {
        let title = "External Monitor Disconnected"
        let body = "External display disconnected. Reset open applications back to MacBook Retina actual size (100%)."
        sendNotification(title: title, body: body)
    }

    public func sendNotification(title: String, body: String) {
        // 1. Deliver via UNUserNotificationCenter
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("[macDisplayMagic] UNUserNotificationCenter delivery warning: \(error.localizedDescription)")
            }
        }

        // 2. Deliver via macOS AppleScript system notification banner fallback
        DispatchQueue.global(qos: .userInitiated).async {
            let cleanTitle = title.replacingOccurrences(of: "\"", with: "\\\"")
            let cleanBody = body.replacingOccurrences(of: "\"", with: "\\\"")
            let scriptSource = "display notification \"\(cleanBody)\" with title \"\(cleanTitle)\""
            if let appleScript = NSAppleScript(source: scriptSource) {
                var error: NSDictionary?
                appleScript.executeAndReturnError(&error)
            }
        }
    }

    // Display notifications even when the app is in foreground
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .list])
    }
}
