import AppKit
import ApplicationServices
import Combine
import Foundation

/// Service observing active application focus, window screen placement, and tab-level zoom state.
public final class WindowTracker: ObservableObject {
    public static let shared = WindowTracker()
    
    // MARK: - Published 3-Level Hierarchy Attributes
    
    // Level 1: Display / Monitor
    @Published public var activeMonitorName: String = "Built-in Display"
    @Published public var activeMonitorModel: String = "Built-in Retina"
    @Published public var activeScreenName: String = "Built-in Screen"
    @Published public var activeScreenCategory: DisplayCategory = .builtIn
    
    // Level 2: Application
    @Published public var activeAppName: String = "None"
    @Published public var activeAppBundleID: String = ""
    
    // Level 3: Active Tab / Sub-Window & Zoom Rate
    @Published public var activeTabTitle: String = "Main View"
    @Published public var activeTabDomain: String? = nil
    @Published public var activeZoomLevelString: String = "100% (Baseline)"
    @Published public var isDomainExcluded: Bool = false

    // MARK: - Tracking Storage
    
    private var appScreenMap: [pid_t: String] = [:] // Map of pid -> last known screen ID
    private var appIsZoomedMap: [pid_t: Bool] = [:] // Map of pid -> whether macDisplayMagic modified zoom
    private var timer: Timer?

    // MARK: - Initialization
    
    public init() {}

    public func getZoomedPIDs() -> Set<pid_t> {
        let pids = appIsZoomedMap.filter { $0.value }.map { $0.key }
        return Set(pids)
    }

    public func clearZoomedStates() {
        appIsZoomedMap.removeAll()
    }

    public func isAppZoomed(pid: pid_t) -> Bool {
        return appIsZoomedMap[pid] ?? false
    }

    public func setAppZoomed(pid: pid_t, isZoomed: Bool) {
        appIsZoomedMap[pid] = isZoomed
    }

    // MARK: - Tracking Loop
    
    public func startTracking() {
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(appDidActivate(_:)),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )

        // Poll active application window position every 1.5s to detect screen drag transitions and tab switches
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

    // MARK: - Application Update Logic
    
    private func updateForApp(_ app: NSRunningApplication) {
        let pid = app.processIdentifier
        let bundleID = app.bundleIdentifier ?? ""
        let name = app.localizedName ?? "App"

        guard bundleID != Bundle.main.bundleIdentifier else { return }

        // Query active screen & window title via AXUIElement
        let appAX = AXUIElementCreateApplication(pid)
        var windowRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(appAX, kAXFocusedWindowAttribute as CFString, &windowRef)

        var currentScreen: NSScreen = NSScreen.main ?? NSScreen.screens[0]
        var currentTitle = "Main View"

        if result == .success, let windowRef = windowRef {
            let windowElement = windowRef as! AXUIElement
            var positionRef: CFTypeRef?
            var sizeRef: CFTypeRef?
            var titleRef: CFTypeRef?

            AXUIElementCopyAttributeValue(windowElement, kAXPositionAttribute as CFString, &positionRef)
            AXUIElementCopyAttributeValue(windowElement, kAXSizeAttribute as CFString, &sizeRef)
            AXUIElementCopyAttributeValue(windowElement, kAXTitleAttribute as CFString, &titleRef)

            if let titleStr = titleRef as? String, !titleStr.isEmpty {
                currentTitle = titleStr
            }

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

        let screenDetails = DisplayInfoProvider.details(for: currentScreen)
        let screenID = DisplayClassifier.displayIDString(screen: currentScreen)
        let screenCategory = DisplayClassifier.classify(screen: currentScreen)

        // Domain exclusion & tab zoom check
        let (excluded, domain) = TabZoomTracker.shared.checkDomainExclusion(bundleID: bundleID, pid: pid, windowTitle: currentTitle)
        let isZoomed = appIsZoomedMap[pid] ?? false
        
        let zoomString: String
        if excluded {
            zoomString = "🚫 Excluded (noZoomingDomain)"
        } else if isZoomed {
            if let action = RulesStore.shared.evaluateRule(appBundleID: bundleID, displayCategory: screenCategory, screen: currentScreen) {
                switch action {
                case .zoomIn(let steps):
                    zoomString = "🔍 Zoom: +\(steps) Steps (\(100 + steps * 25)%)"
                case .zoomOut(let steps):
                    zoomString = "🔍 Zoom: -\(steps) Steps (\(max(50, 100 - steps * 25))%)"
                case .reset100:
                    zoomString = "🔍 Zoom: 100% (Baseline)"
                }
            } else {
                zoomString = "🔍 Zoom: Active"
            }
        } else {
            zoomString = "🔍 Zoom: 100% (Baseline)"
        }

        DispatchQueue.main.async {
            self.activeMonitorName = screenDetails.name
            self.activeMonitorModel = screenDetails.modelName
            self.activeScreenCategory = screenCategory
            
            self.activeAppName = name
            self.activeAppBundleID = bundleID
            
            self.activeTabTitle = currentTitle
            self.activeTabDomain = domain
            self.activeZoomLevelString = zoomString
            self.isDomainExcluded = excluded
        }

        // Intercept tab focus for keepZooming
        TabZoomTracker.shared.handleTabFocus(
            pid: pid,
            bundleID: bundleID,
            appName: name,
            tabTitle: currentTitle,
            targetScreen: currentScreen,
            category: screenCategory
        )

        // Check if window transitioned to a different screen
        let lastScreenID = appScreenMap[pid]
        if let lastScreenID = lastScreenID {
            if lastScreenID != screenID {
                appScreenMap[pid] = screenID
                handleWindowScreenTransition(app: app, targetScreen: currentScreen, category: screenCategory, screenID: screenID, windowTitle: currentTitle)
            }
        } else {
            // Store initial screen placement for app without firing false transition
            appScreenMap[pid] = screenID
        }
    }

    private func handleWindowScreenTransition(app: NSRunningApplication, targetScreen: NSScreen, category: DisplayCategory, screenID: String, windowTitle: String? = nil) {
        let pid = app.processIdentifier
        let bundleID = app.bundleIdentifier ?? ""
        let isBuiltIn = CGDisplayIsBuiltin((targetScreen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID) ?? 0) != 0

        let appName = app.localizedName ?? "Application"
        let (isExcluded, _) = TabZoomTracker.shared.checkDomainExclusion(bundleID: bundleID, pid: pid, windowTitle: windowTitle)

        if isBuiltIn {
            // Returning to Built-in Retina screen: reset tracked tabs and app zoom
            TabZoomTracker.shared.resetTrackedTabs(pid: pid, appName: appName)
            if appIsZoomedMap[pid] == true {
                print("[macDisplayMagic] Resetting '\(appName)' back to 100% on Built-in Display.")
                ZoomEngine.shared.execute(action: .reset100, for: pid, appName: appName)
                appIsZoomedMap[pid] = false
                NotificationService.shared.sendZoomNotification(appName: appName, screenName: targetScreen.localizedName, category: category, action: .reset100)
            }
            return
        }

        // AutoMinimize Override Check: AutoMinimize takes absolute precedence over Zoom Rules
        if AutoMinimizeService.shared.shouldAutoMinimize(bundleID: bundleID, windowTitle: activeTabTitle, screen: targetScreen) {
            print("[macDisplayMagic] AutoMinimize rule active for '\(appName)'. Minimizing window and overriding custom zoom rules.")
            AutoMinimizeService.shared.executeAutoMinimize()
            return
        }

        if isExcluded {
            print("[macDisplayMagic] Active domain is excluded via noZoomingDomain. Skipping transition zoom for '\(appName)'.")
            return
        }

        guard let action = RulesStore.shared.evaluateRule(appBundleID: bundleID, displayCategory: category, screen: targetScreen) else {
            print("[macDisplayMagic] No enabled zoom rule for screen '\(targetScreen.localizedName)' (\(category.rawValue)). Skipping zoom action.")
            return
        }

        switch action {
        case .reset100:
            if appIsZoomedMap[pid] == true {
                print("[macDisplayMagic] Resetting '\(appName)' back to 100%.")
                ZoomEngine.shared.execute(action: action, for: pid, appName: appName)
                appIsZoomedMap[pid] = false
                NotificationService.shared.sendZoomNotification(appName: appName, screenName: targetScreen.localizedName, category: category, action: action)
            }

        case .zoomIn, .zoomOut:
            print("[macDisplayMagic] Executing \(action) for '\(appName)' on screen '\(targetScreen.localizedName)'.")
            ZoomEngine.shared.execute(action: action, for: pid, appName: appName)
            appIsZoomedMap[pid] = true
            NotificationService.shared.sendZoomNotification(appName: appName, screenName: targetScreen.localizedName, category: category, action: action)
        }
    }

    private func screenContaining(point: CGPoint) -> NSScreen? {
        guard let primaryScreen = NSScreen.screens.first else { return nil }
        let primaryHeight = primaryScreen.frame.height
        let cocoaPoint = NSPoint(x: point.x, y: primaryHeight - point.y)

        return NSScreen.screens.first(where: { NSPointInRect(cocoaPoint, $0.frame) })
    }
}
