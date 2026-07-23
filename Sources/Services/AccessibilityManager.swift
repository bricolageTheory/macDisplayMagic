import AppKit
import ApplicationServices
import Combine

/// Manages macOS Accessibility API trust state for the application.
///
/// `macDisplayMagic` requires Accessibility access (enabled in System Settings → Privacy & Security)
/// to post synthetic key events (`CGEvent.postToPid`) to other running applications for zoom control.
/// This singleton checks and requests that permission, and publishes live trust-state changes
/// so the UI can prompt the user when access is revoked.
public final class AccessibilityManager: ObservableObject {

    // MARK: - Shared Instance

    public static let shared = AccessibilityManager()

    // MARK: - Published State

    /// `true` when the app has been granted Accessibility permission by the user.
    @Published public var isAccessibilityTrusted: Bool = AXIsProcessTrusted()

    // MARK: - Initialisation

    public init() {
        refreshStatus()
    }

    // MARK: - Public Interface

    /// Synchronises the published `isAccessibilityTrusted` value against the current system state.
    /// Safe to call from any thread; UI updates are dispatched to the main queue.
    public func refreshStatus() {
        let current = AXIsProcessTrusted()
        if self.isAccessibilityTrusted != current {
            DispatchQueue.main.async {
                self.isAccessibilityTrusted = current
            }
        }
    }

    /// Checks current Accessibility trust status and, if not yet granted, presents the
    /// macOS system prompt asking the user to grant access.
    ///
    /// - Returns: `true` when the process is already trusted; `false` when the prompt was shown.
    @discardableResult
    public func checkAndRequestAccessibility() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        let trusted = AXIsProcessTrustedWithOptions(options)
        refreshStatus()
        return trusted
    }
}
