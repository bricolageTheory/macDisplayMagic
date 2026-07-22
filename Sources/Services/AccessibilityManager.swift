import AppKit
import ApplicationServices
import Combine

public final class AccessibilityManager: ObservableObject {
    public static let shared = AccessibilityManager()

    @Published public var isAccessibilityTrusted: Bool = AXIsProcessTrusted()

    public init() {
        refreshStatus()
    }

    public func refreshStatus() {
        let current = AXIsProcessTrusted()
        if self.isAccessibilityTrusted != current {
            DispatchQueue.main.async {
                self.isAccessibilityTrusted = current
            }
        }
    }

    @discardableResult
    public func checkAndRequestAccessibility() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        let trusted = AXIsProcessTrustedWithOptions(options)
        refreshStatus()
        return trusted
    }

    /// Gets the application bundle identifier for a given process identifier
    public func bundleID(for pid: pid_t) -> String? {
        if let app = NSRunningApplication(processIdentifier: pid) {
            return app.bundleIdentifier
        }
        return nil
    }

    /// Helper to fetch active application name
    public func appName(for pid: pid_t) -> String {
        if let app = NSRunningApplication(processIdentifier: pid) {
            return app.localizedName ?? "App (\(pid))"
        }
        return "Process \(pid)"
    }
}
