import AppKit
import Foundation

/// Stub notification service — all methods are intentionally no-ops.
///
/// Notifications were disabled per user configuration preference.
/// The class is retained so that call-sites in `WindowTracker`, `TabZoomTracker`,
/// and `ZoomEngine` continue to compile without modification, making it trivial
/// to re-enable notifications in the future by implementing the method bodies.
///
/// To re-enable, replace each method stub with a `UNUserNotificationCenter` request.
public final class NotificationService: NSObject {

    // MARK: - Shared Instance

    public static let shared = NotificationService()

    // MARK: - Initialisation

    public override init() {
        super.init()
    }

    // MARK: - Authorization

    /// No-op. Implement to call `UNUserNotificationCenter.current().requestAuthorization(...)`.
    public func requestAuthorization() {}

    // MARK: - Notification Dispatch

    /// No-op. Would notify the user that a window's zoom level was changed on a new screen.
    public func sendZoomNotification(appName: String, screenName: String, category: DisplayCategory, action: ZoomAction) {}

    /// No-op. Would notify the user that a browser tab's zoom level was changed.
    public func sendTabZoomNotification(appName: String, tabTitle: String, screenName: String, action: ZoomAction) {}

    /// No-op. Would notify the user that an external display was disconnected and zoom was reset.
    public func sendDisconnectNotification() {}

    /// No-op generic notification entry point.
    public func sendNotification(title: String, body: String) {}
}
