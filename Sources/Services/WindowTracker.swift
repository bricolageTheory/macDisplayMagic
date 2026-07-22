import AppKit
import ApplicationServices
import Combine
import Foundation

public final class WindowTracker: ObservableObject {
    @Published public var activeAppName: String = "None"
    @Published public var activeAppBundleID: String = ""
    @Published public var activeScreenName: String = "Built-in Screen"
    @Published public var activeScreenCategory: DisplayCategory = .builtIn

    private var appScreenMap: [pid_t: String] = [:] // Map of pid -> last known screen ID
    private var appIsZoomedMap: [pid_t: Bool] = [:] // Map of pid -> whether macDisplayMagic modified zoom
    private var timer: Timer?

    public init() {}

    public func getZoomedPIDs() -> Set<pid_t> {
        let pids = appIsZoomedMap.filter { $0.value }.map { $0.key }
        return Set(pids)
    }

    public func clearZoomedStates() {
        appIsZoomedMap.removeAll()
    }

    public func startTracking() {
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(appDidActivate(_:)),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )

        // Poll active application window position every 1.5s to detect screen drag transitions
        timer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            self?.checkActiveWindowScreen()
        }
    }

    public func stopTracking() {
        NSWorkspace.shared.notificationCenter.removeObserver(self)
        timer?.invalidate()
        timer = nil
    }

    @objc private func appDidActivate(_ notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else { return }
        updateForApp(app)
    }

    public func checkActiveWindowScreen() {
        guard let activeApp = NSWorkspace.shared.menuBarOwningApplication ?? NSWorkspace.shared.runningApplications.first(where: { $0.isActive }) else { return }
        updateForApp(activeApp)
    }

    private func updateForApp(_ app: NSRunningApplication) {
        let pid = app.processIdentifier
        let bundleID = app.bundleIdentifier ?? ""
        let name = app.localizedName ?? "App"

        guard bundleID != Bundle.main.bundleIdentifier else { return }

        // Find which screen this app's window is currently on using AXUIElement
        let appAX = AXUIElementCreateApplication(pid)
        var windowRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(appAX, kAXFocusedWindowAttribute as CFString, &windowRef)

        var currentScreen: NSScreen = NSScreen.main ?? NSScreen.screens[0]

        if result == .success, let windowRef = windowRef {
            let windowElement = windowRef as! AXUIElement
            var positionRef: CFTypeRef?
            var sizeRef: CFTypeRef?

            AXUIElementCopyAttributeValue(windowElement, kAXPositionAttribute as CFString, &positionRef)
            AXUIElementCopyAttributeValue(windowElement, kAXSizeAttribute as CFString, &sizeRef)

            var point = CGPoint.zero
            var size = CGSize.zero

            if let positionRef = positionRef {
                AXValueGetValue(positionRef as! AXValue, .cgPoint, &point)
            }
            if let sizeRef = sizeRef {
                AXValueGetValue(sizeRef as! AXValue, .cgSize, &size)
            }

            let windowCenter = CGPoint(x: point.x + size.width / 2.0, y: point.y + size.height / 2.0)
            if let targetScreen = screenContaining(point: windowCenter) {
                currentScreen = targetScreen
            }
        }

        let screenID = DisplayClassifier.displayIDString(screen: currentScreen)
        let screenCategory = DisplayClassifier.classify(screen: currentScreen)

        DispatchQueue.main.async {
            self.activeAppName = name
            self.activeAppBundleID = bundleID
            self.activeScreenName = currentScreen.localizedName
            self.activeScreenCategory = screenCategory
        }

        // Check if window transitioned to a different screen
        let lastScreenID = appScreenMap[pid]
        if let lastScreenID = lastScreenID {
            if lastScreenID != screenID {
                appScreenMap[pid] = screenID
                handleWindowScreenTransition(app: app, targetScreen: currentScreen, category: screenCategory, screenID: screenID)
            }
        } else {
            // Store initial screen placement for app without firing false transition
            appScreenMap[pid] = screenID
        }
    }

    private func handleWindowScreenTransition(app: NSRunningApplication, targetScreen: NSScreen, category: DisplayCategory, screenID: String) {
        let pid = app.processIdentifier
        let bundleID = app.bundleIdentifier ?? ""
        guard let action = RulesStore.shared.evaluateRule(appBundleID: bundleID, displayCategory: category, screen: targetScreen) else {
            print("[macDisplayMagic] No enabled zoom rule for screen '\(targetScreen.localizedName)' (\(category.rawValue)). Skipping zoom action.")
            return
        }

        let appName = app.localizedName ?? "Application"
        let isCurrentlyZoomed = appIsZoomedMap[pid] ?? false

        switch action {
        case .reset100:
            if isCurrentlyZoomed {
                print("[macDisplayMagic] Resetting '\(appName)' back to 100% (was previously zoomed by macDisplayMagic).")
                ZoomEngine.shared.execute(action: action, for: pid, appName: appName)
                appIsZoomedMap[pid] = false
                NotificationService.shared.sendZoomNotification(appName: appName, screenName: targetScreen.localizedName, category: category, action: action)
            } else {
                print("[macDisplayMagic] '\(appName)' was not zoomed by macDisplayMagic. Skipping reset & notification.")
            }

        case .zoomIn, .zoomOut:
            print("[macDisplayMagic] Executing \(action) for '\(appName)' on screen '\(targetScreen.localizedName)'.")
            ZoomEngine.shared.execute(action: action, for: pid, appName: appName)
            appIsZoomedMap[pid] = true
            NotificationService.shared.sendZoomNotification(appName: appName, screenName: targetScreen.localizedName, category: category, action: action)
        }
    }

    private func screenContaining(point: CGPoint) -> NSScreen? {
        // macOS CG screen coordinates vs Cocoa screen coordinates flip top/bottom
        guard let primaryScreen = NSScreen.screens.first else { return nil }
        let primaryHeight = primaryScreen.frame.height
        let cocoaPoint = NSPoint(x: point.x, y: primaryHeight - point.y)

        return NSScreen.screens.first(where: { NSPointInRect(cocoaPoint, $0.frame) })
    }
}
