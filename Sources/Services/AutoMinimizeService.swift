import AppKit
import ApplicationServices
import Foundation

/// Service executing silent window minimization for configured AutoMinimize rules on monitor connection.
public final class AutoMinimizeService {
    public static let shared = AutoMinimizeService()

    /// Evaluates if an external monitor matches a rule's display target condition.
    public func matchesDisplayTarget(target: AutoMinimizeDisplayTarget, screen: NSScreen) -> Bool {
        let hardwareID = DisplayClassifier.permanentHardwareID(for: screen)
        let isKnown = DisplayHistoryStore.shared.isKnownMonitor(hardwareID: hardwareID)

        switch target {
        case .anyExternal:
            return true
        case .unknownOnly:
            return !isKnown
        case .knownOnly:
            return isKnown
        case .specific(let targetID):
            return hardwareID == targetID
        }
    }

    /// Evaluates whether an application and window should be auto-minimized for a specific screen, overriding zoom rules.
    public func shouldAutoMinimize(bundleID: String, windowTitle: String, screen: NSScreen) -> Bool {
        guard AppSettings.shared.enableAutoMinimize else { return false }
        let rules = AppSettings.shared.autoMinimizeRules.filter { $0.isEnabled }
        guard !rules.isEmpty else { return false }

        for rule in rules {
            if rule.targetBundleIDs.contains(bundleID) && matchesDisplayTarget(target: rule.displayTarget, screen: screen) {
                let pattern = rule.windowTitlePattern.lowercased().trimmingCharacters(in: .whitespaces)
                if pattern.isEmpty || windowTitle.lowercased().contains(pattern) {
                    return true
                }
            }
        }
        return false
    }

    /// Executes all active AutoMinimize rules when an external monitor connects.
    /// Operates completely silently with **zero notifications**.
    public func executeAutoMinimize() {
        guard AppSettings.shared.enableAutoMinimize else { return }
        let rules = AppSettings.shared.autoMinimizeRules.filter { $0.isEnabled }
        guard !rules.isEmpty else { return }

        let externalScreens = NSScreen.screens.filter { !DisplayClassifier.isBuiltIn(screen: $0) }
        guard let currentExternalScreen = externalScreens.first else { return }

        print("[macDisplayMagic] AutoMinimize: External monitor connected. Evaluating \(rules.count) rule(s)...")

        let runningApps = NSWorkspace.shared.runningApplications
        for rule in rules {
            guard matchesDisplayTarget(target: rule.displayTarget, screen: currentExternalScreen) else { continue }
            for bundleID in rule.targetBundleIDs {
                let matchingApps = runningApps.filter { $0.bundleIdentifier == bundleID }
                for app in matchingApps {
                    minimizeWindows(for: app, titlePattern: rule.windowTitlePattern)
                }
            }
        }
    }

    /// Minimizes windows for a specific application matching title pattern via AXUIElement.
    private func minimizeWindows(for app: NSRunningApplication, titlePattern: String) {
        let pid = app.processIdentifier
        let appName = app.localizedName ?? "App"
        let appAX = AXUIElementCreateApplication(pid)

        var windowsRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(appAX, kAXWindowsAttribute as CFString, &windowsRef) == .success,
              let windows = windowsRef as? [AXUIElement] else {
            app.hide()
            print("[macDisplayMagic] AutoMinimize: Hid application '\(appName)' (PID: \(pid)).")
            return
        }

        let pattern = titlePattern.lowercased().trimmingCharacters(in: .whitespaces)

        for window in windows {
            if !pattern.isEmpty {
                var titleRef: CFTypeRef?
                if AXUIElementCopyAttributeValue(window, kAXTitleAttribute as CFString, &titleRef) == .success,
                   let title = titleRef as? String {
                    if !title.lowercased().contains(pattern) {
                        continue
                    }
                }
            }

            let result = AXUIElementSetAttributeValue(window, kAXMinimizedAttribute as CFString, true as CFTypeRef)
            if result == .success {
                print("[macDisplayMagic] AutoMinimize: Minimized window for '\(appName)'.")
            } else {
                minimizeViaAppleScript(pid: pid)
            }
        }
    }

    private func minimizeViaAppleScript(pid: pid_t) {
        let scriptSource = """
        tell application "System Events"
            set proc to first process whose process identifier is \(pid)
            try
                set miniaturized of every window of proc to true
            end try
        end tell
        """
        if let script = NSAppleScript(source: scriptSource) {
            var error: NSDictionary?
            script.executeAndReturnError(&error)
        }
    }
}
