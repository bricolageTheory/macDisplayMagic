import AppKit
import Foundation

/// Notification service disabled per user configuration.
public final class NotificationService: NSObject {
    public static let shared = NotificationService()

    public override init() {
        super.init()
    }

    public func requestAuthorization() {
        // Notifications disabled
    }

    public func sendZoomNotification(appName: String, screenName: String, category: DisplayCategory, action: ZoomAction) {
        // Notifications disabled
    }

    public func sendTabZoomNotification(appName: String, tabTitle: String, screenName: String, action: ZoomAction) {
        // Notifications disabled
    }

    public func sendDisconnectNotification() {
        // Notifications disabled
    }

    public func sendNotification(title: String, body: String) {
        // Notifications disabled
    }
}
