import AppKit
import CoreGraphics
import Foundation

// MARK: - DisplayWatcherDelegate

/// Callback interface receiving display lifecycle events from `DisplayWatcher`.
///
/// Implement this protocol on your application delegate (or any coordinator) to react
/// to external monitor connections, disconnections, and configuration changes.
public protocol DisplayWatcherDelegate: AnyObject {
    /// Called when a new external screen is connected and ready.
    func displayDidConnect(screen: NSScreen)
    /// Called when an external display is unplugged or disabled.
    func displayDidDisconnect()
    /// Called when the display topology changes (e.g. resolution, arrangement, mirroring).
    func displayConfigurationDidChange()
}

// MARK: - DisplayWatcher

/// Listens for macOS display hot-plug events via `CoreGraphics` reconfiguration callbacks.
///
/// Registers a `CGDisplayReconfigurationCallBack` at startup and translates raw `CGDisplayChangeSummaryFlags`
/// into typed delegate calls.  A short delay is applied before notifying the delegate to allow macOS
/// to finish repositioning windows onto the remaining screens.
public final class DisplayWatcher {

    // MARK: - Properties

    /// Delegate receiving display lifecycle events. Held weakly to avoid retain cycles.
    public weak var delegate: DisplayWatcherDelegate?

    private var isListening: Bool = false

    // MARK: - Initialisation

    public init() {}

    // MARK: - Public Interface

    /// Registers the CoreGraphics display reconfiguration callback and begins listening.
    /// Safe to call multiple times; subsequent calls are ignored if already listening.
    public func startListening() {
        guard !isListening else { return }
        isListening = true

        // Bridge `self` through an unretained opaque pointer for the C callback.
        let context = Unmanaged.passUnretained(self).toOpaque()

        let callback: CGDisplayReconfigurationCallBack = { (displayID, flags, userInfo) in
            guard let userInfo = userInfo else { return }
            let watcher = Unmanaged<DisplayWatcher>.fromOpaque(userInfo).takeUnretainedValue()
            watcher.handleDisplayReconfiguration(displayID: displayID, flags: flags)
        }

        CGDisplayRegisterReconfigurationCallback(callback, context)
        print("[macDisplayMagic] DisplayWatcher started listening for display hot-plug events.")
    }

    // MARK: - Private Helpers

    /// Translates raw CoreGraphics display flags into delegate calls.
    ///
    /// A 1-second delay is used for add/remove events so that macOS can fully reposition
    /// existing windows before the app applies zoom adjustments.
    private func handleDisplayReconfiguration(displayID: CGDirectDisplayID, flags: CGDisplayChangeSummaryFlags) {
        if flags.contains(.removeFlag) || flags.contains(.disabledFlag) {
            // External display unplugged or disabled — batch-reset zoom after macOS repositions windows.
            print("[macDisplayMagic] External display removal detected (ID: \(displayID)).")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.delegate?.displayDidDisconnect()
            }
        } else if flags.contains(.addFlag) {
            // New external display connected — apply presets after macOS finishes setup.
            print("[macDisplayMagic] External display connection detected (ID: \(displayID)).")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.delegate?.displayConfigurationDidChange()
            }
        } else {
            // Other configuration change (resolution, arrangement, mirroring).
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.delegate?.displayConfigurationDidChange()
            }
        }
    }
}
