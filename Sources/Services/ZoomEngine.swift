import AppKit
import CoreGraphics
import Foundation

public final class ZoomEngine {
    public static let shared = ZoomEngine()

    // Virtual keycodes
    private let keycode0: CGKeyCode = 0x1D  // '0' key
    private let keycodePlus: CGKeyCode = 0x18 // '=' / '+' key
    private let keycodeMinus: CGKeyCode = 0x1B // '-' key

    /// Executes the specified zoom action for a target running application process ID.
    public func execute(action: ZoomAction, for pid: pid_t, appName: String = "") {
        switch action {
        case .reset100:
            print("[macDisplayMagic] Resetting zoom to 100% (Cmd+0) for \(appName) [pid: \(pid)]")
            sendKeyCombination(keycode: keycode0, flags: .maskCommand, pid: pid)

        case .zoomIn(let steps):
            print("[macDisplayMagic] Zooming in +\(steps) (Cmd++) for \(appName) [pid: \(pid)]")
            for _ in 0..<max(1, steps) {
                sendKeyCombination(keycode: keycodePlus, flags: .maskCommand, pid: pid)
                usleep(50_000) // 50ms pause between keypresses
            }

        case .zoomOut(let steps):
            print("[macDisplayMagic] Zooming out -\(steps) (Cmd--) for \(appName) [pid: \(pid)]")
            for _ in 0..<max(1, steps) {
                sendKeyCombination(keycode: keycodeMinus, flags: .maskCommand, pid: pid)
                usleep(50_000)
            }
        }
    }

    /// Reset open applications back to 100% zoom (used on display disconnect)
    public func resetAllRunningAppsToDefault(runningApps: [NSRunningApplication], targetPIDs: Set<pid_t>? = nil) {
        let supportedApps = runningApps.filter { app in
            guard app.activationPolicy == .regular, let bundleID = app.bundleIdentifier else { return false }
            if let pids = targetPIDs, !pids.contains(app.processIdentifier) {
                return false
            }
            return !bundleID.hasPrefix("com.apple.finder") && app.processIdentifier != ProcessInfo.processInfo.processIdentifier
        }

        guard !supportedApps.isEmpty else {
            print("[macDisplayMagic] No active applications were zoomed by macDisplayMagic. Skipping disconnect reset.")
            return
        }

        print("[macDisplayMagic] Executing batch reset to 100% across \(supportedApps.count) zoomed application(s)...")
        for app in supportedApps {
            execute(action: .reset100, for: app.processIdentifier, appName: app.localizedName ?? "")
        }
        NotificationService.shared.sendDisconnectNotification()
    }

    private func sendKeyCombination(keycode: CGKeyCode, flags: CGEventFlags, pid: pid_t) {
        guard let keyDown = CGEvent(keyboardEventSource: nil, virtualKey: keycode, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: nil, virtualKey: keycode, keyDown: false) else {
            return
        }

        keyDown.flags = flags
        keyUp.flags = flags

        // Post directly to the target application process
        keyDown.postToPid(pid)
        keyUp.postToPid(pid)
    }
}
