import AppKit
import Combine
import Foundation

/// Service tracking tab-level zoom state and domain exclusions for multi-tab applications.
public final class TabZoomTracker: ObservableObject {
    public static let shared = TabZoomTracker()

    // MARK: - Tracking Storage
    
    /// Maps Process ID (PID) to dictionary of [TabIdentifier: AppliedZoomSteps]
    private var processTabZoomMap: [pid_t: [String: Int]] = [:]
    /// Maps Process ID (PID) to set of tab identifiers that were zoomed on external screen and require reset when focused on Built-in display
    private var pendingResetMap: [pid_t: Set<String>] = [:]
    /// Maps Process ID (PID) to active tab title
    private var lastActiveTabMap: [pid_t: String] = [:]

    // MARK: - Domain Exclusion Check
    
    /// Checks if the current active tab domain matches user's `noZoomDomains` exclusion list.
    /// - Parameters:
    ///   - bundleID: Application bundle identifier.
    ///   - pid: Process identifier.
    ///   - windowTitle: Optional active window title.
    /// - Returns: Tuple containing exclusion status and domain name if available.
    public func checkDomainExclusion(bundleID: String, pid: pid_t, windowTitle: String? = nil) -> (isExcluded: Bool, domain: String?) {
        guard AppSettings.shared.enableNoZoomingDomain else { return (false, nil) }
        guard let domain = DomainExtractor.shared.extractDomain(bundleID: bundleID, pid: pid, windowTitle: windowTitle) else {
            return (false, nil)
        }

        let excludedList = AppSettings.shared.noZoomDomains
        let isExcluded = excludedList.contains { excluded in
            let cleanExcluded = excluded.lowercased().trimmingCharacters(in: .whitespaces)
            return !cleanExcluded.isEmpty && domain.lowercased().contains(cleanExcluded)
        }

        return (isExcluded, domain)
    }

    // MARK: - Tab Focus Interceptor (keepZooming Engine)
    
    /// Intercepts tab focus or title change events and applies zoom for unvisited tabs on external displays or resets tabs on Built-in display.
    public func handleTabFocus(pid: pid_t, bundleID: String, appName: String, tabTitle: String, targetScreen: NSScreen, category: DisplayCategory) {
        guard AppSettings.shared.enableKeepZooming else { return }
        
        let isBuiltIn = CGDisplayIsBuiltin((targetScreen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID) ?? 0) != 0
        let (isExcluded, domain) = checkDomainExclusion(bundleID: bundleID, pid: pid, windowTitle: tabTitle)
        let tabID = "\(tabTitle)_\(domain ?? "nodomain")"

        // If domain is on noZoomingDomain list, skip zooming and reset logic entirely
        if isExcluded {
            return
        }

        if isBuiltIn {
            // Check if THIS SPECIFIC TAB is pending reset from previous external zoom
            if var pendingSet = pendingResetMap[pid], !pendingSet.isEmpty {
                let matchesTab = pendingSet.contains(tabID) || pendingSet.contains(tabTitle)
                if matchesTab {
                    print("[macDisplayMagic] keepZooming: Resetting deferred zoomed tab '\(tabTitle)' focused on Built-in Display for '\(appName)'.")
                    ZoomEngine.shared.execute(action: .reset100, for: pid, appName: appName)
                    NotificationService.shared.sendTabZoomNotification(appName: appName, tabTitle: tabTitle, screenName: targetScreen.localizedName, action: .reset100)
                    
                    pendingSet.remove(tabID)
                    pendingSet.remove(tabTitle)
                    if pendingSet.isEmpty {
                        pendingResetMap.removeValue(forKey: pid)
                    } else {
                        pendingResetMap[pid] = pendingSet
                    }
                }
            }
            return
        }

        var tabMap = processTabZoomMap[pid] ?? [:]

        // If tab was already zoomed for this external session, skip duplicate zoom
        if tabMap[tabID] != nil {
            lastActiveTabMap[pid] = tabTitle
            return
        }

        // Evaluate zoom rule for target screen
        guard let action = RulesStore.shared.evaluateRule(appBundleID: bundleID, displayCategory: category, screen: targetScreen) else {
            return
        }

        switch action {
        case .zoomIn(let steps):
            print("[macDisplayMagic] keepZooming: New tab focused '\(tabTitle)' in '\(appName)'. Applying Zoom In +\(steps)...")
            ZoomEngine.shared.execute(action: action, for: pid, appName: appName)
            NotificationService.shared.sendTabZoomNotification(appName: appName, tabTitle: tabTitle, screenName: targetScreen.localizedName, action: action)
            tabMap[tabID] = steps
            processTabZoomMap[pid] = tabMap
            lastActiveTabMap[pid] = tabTitle

        case .zoomOut(let steps):
            print("[macDisplayMagic] keepZooming: New tab focused '\(tabTitle)' in '\(appName)'. Applying Zoom Out -\(steps)...")
            ZoomEngine.shared.execute(action: action, for: pid, appName: appName)
            NotificationService.shared.sendTabZoomNotification(appName: appName, tabTitle: tabTitle, screenName: targetScreen.localizedName, action: action)
            tabMap[tabID] = -steps
            processTabZoomMap[pid] = tabMap
            lastActiveTabMap[pid] = tabTitle

        case .reset100:
            break
        }
    }

    // MARK: - Reset & Clear Methods
    
    /// Resets zoom levels for active front tab and queues all other visited tabs for deferred reset when focused on Built-in display.
    public func resetTrackedTabs(pid: pid_t, appName: String) {
        guard let tabMap = processTabZoomMap[pid], !tabMap.isEmpty else { return }
        print("[macDisplayMagic] keepZooming: Resetting active front tab and queueing \(tabMap.count) tab(s) for focus reset on Built-in Display...")
        
        var pendingSet = Set(tabMap.keys)
        
        // Execute reset for active front tab
        ZoomEngine.shared.execute(action: .reset100, for: pid, appName: appName)
        
        if let lastTab = lastActiveTabMap[pid] {
            pendingSet.remove(lastTab)
        }
        
        if !pendingSet.isEmpty {
            pendingResetMap[pid] = pendingSet
        } else {
            pendingResetMap.removeValue(forKey: pid)
        }
        
        processTabZoomMap.removeValue(forKey: pid)
        lastActiveTabMap.removeValue(forKey: pid)
    }

    /// Clears tracking cache for process.
    public func clearTracking(pid: pid_t) {
        processTabZoomMap.removeValue(forKey: pid)
        pendingResetMap.removeValue(forKey: pid)
        lastActiveTabMap.removeValue(forKey: pid)
    }
}
