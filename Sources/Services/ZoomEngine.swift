import AppKit
import CoreGraphics
import Foundation

/// Dispatches keyboard shortcut-based zoom commands to target application processes.
///
/// `ZoomEngine` uses macOS `CGEvent` to post synthetic key-press events directly to the
/// target application's process ID (PID) via `CGEvent.postToPid(_:)`, simulating the
/// standard macOS zoom shortcuts:
///
/// | Shortcut | Action |
/// |---|---|
/// | `Cmd + 0` | Reset to 100% |
/// | `Cmd + =` ('+') | Zoom In one step |
/// | `Cmd + -` | Zoom Out one step |
///
/// This approach is universal — it works with any application that respects standard
/// macOS zoom keyboard shortcuts, including browsers, Preview, editors, and document apps.
///
/// - Important: Requires **Accessibility permission** (`AXIsProcessTrusted()`) to post
///   events to other application processes. Without it, `CGEvent.postToPid` silently fails.
public final class ZoomEngine {

    // MARK: - Shared Instance

    public static let shared = ZoomEngine()

    // MARK: - Virtual Key Codes

    /// Virtual keycode for the `0` key — used for `Cmd + 0` (reset to 100%).
    private let keycode0: CGKeyCode = 0x1D
    /// Virtual keycode for the `=` / `+` key — used for `Cmd + =` (zoom in).
    private let keycodePlus: CGKeyCode = 0x18
    /// Virtual keycode for the `-` key — used for `Cmd + -` (zoom out).
    private let keycodeMinus: CGKeyCode = 0x1B

    // MARK: - Public Interface

    /// Executes the specified `ZoomAction` targeting a running application by PID.
    ///
    /// Multi-step zoom actions (e.g. `zoomIn(steps: 2)`) post the shortcut once per step
    /// with a 50 ms inter-press delay to ensure each keypress registers before the next fires.
    ///
    /// - Parameters:
    ///   - action: The zoom operation to perform (reset, zoom in N steps, zoom out N steps).
    ///   - pid: The process identifier of the target application.
    ///   - appName: Human-readable application name used for diagnostic logging only.
    public func execute(action: ZoomAction, for pid: pid_t, appName: String = "") {
        switch action {
        case .reset100:
            print("[macDisplayMagic] Resetting zoom to 100% (Cmd+0) for \(appName) [pid: \(pid)]")
            sendKeyCombination(keycode: keycode0, flags: .maskCommand, pid: pid)

        case .zoomIn(let steps):
            print("[macDisplayMagic] Zooming in +\(steps) (Cmd++) for \(appName) [pid: \(pid)]")
            for _ in 0..<max(1, steps) {
                sendKeyCombination(keycode: keycodePlus, flags: .maskCommand, pid: pid)
                usleep(50_000) // 50 ms pause between repeated keypresses
            }

        case .zoomOut(let steps):
            print("[macDisplayMagic] Zooming out -\(steps) (Cmd--) for \(appName) [pid: \(pid)]")
            for _ in 0..<max(1, steps) {
                sendKeyCombination(keycode: keycodeMinus, flags: .maskCommand, pid: pid)
                usleep(50_000)
            }
        }
    }

    /// Resets zoom to 100% for all running applications that were previously zoomed by `macDisplayMagic`.
    ///
    /// Called automatically when an external display is disconnected, ensuring that applications
    /// which were zoomed for the external screen return to their default zoom level on the built-in display.
    ///
    /// - Parameters:
    ///   - runningApps: The current list of running applications (typically `NSWorkspace.shared.runningApplications`).
    ///   - targetPIDs: Optional set of PIDs to restrict the reset to. When `nil`, all regular-policy apps are considered.
    public func resetAllRunningAppsToDefault(runningApps: [NSRunningApplication], targetPIDs: Set<pid_t>? = nil) {
        let appsToReset = runningApps.filter { app in
            guard app.activationPolicy == .regular, let bundleID = app.bundleIdentifier else { return false }
            if let pids = targetPIDs, !pids.contains(app.processIdentifier) { return false }
            // Exclude Finder (zoom shortcuts have no effect) and this process itself.
            return !bundleID.hasPrefix("com.apple.finder") && app.processIdentifier != ProcessInfo.processInfo.processIdentifier
        }

        guard !appsToReset.isEmpty else {
            print("[macDisplayMagic] No active applications were zoomed by macDisplayMagic. Skipping disconnect reset.")
            return
        }

        print("[macDisplayMagic] Executing batch reset to 100% across \(appsToReset.count) zoomed application(s)...")
        for app in appsToReset {
            execute(action: .reset100, for: app.processIdentifier, appName: app.localizedName ?? "")
        }
        NotificationService.shared.sendDisconnectNotification()
    }

    // MARK: - Private Helpers

    /// Posts a key-down + key-up `CGEvent` pair with the specified modifier flags to a target PID.
    ///
    /// - Parameters:
    ///   - keycode: The virtual key code to simulate.
    ///   - flags: Modifier key flags (e.g. `.maskCommand`).
    ///   - pid: The target application process identifier.
    private func sendKeyCombination(keycode: CGKeyCode, flags: CGEventFlags, pid: pid_t) {
        guard let keyDown = CGEvent(keyboardEventSource: nil, virtualKey: keycode, keyDown: true),
              let keyUp   = CGEvent(keyboardEventSource: nil, virtualKey: keycode, keyDown: false) else {
            return
        }
        keyDown.flags = flags
        keyUp.flags   = flags
        keyDown.postToPid(pid)
        keyUp.postToPid(pid)
    }
}
