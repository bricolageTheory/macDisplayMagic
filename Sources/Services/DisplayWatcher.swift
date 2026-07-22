import AppKit
import CoreGraphics
import Foundation

public protocol DisplayWatcherDelegate: AnyObject {
    func displayDidConnect(screen: NSScreen)
    func displayDidDisconnect()
    func displayConfigurationDidChange()
}

public final class DisplayWatcher {
    public weak var delegate: DisplayWatcherDelegate?

    private var previousScreenCount: Int = 0
    private var isListening: Bool = false

    public init() {
        previousScreenCount = NSScreen.screens.count
    }

    public func startListening() {
        guard !isListening else { return }
        isListening = true

        let callback: CGDisplayReconfigurationCallBack = { (displayID, flags, userInfo) in
            guard let userInfo = userInfo else { return }
            let watcher = Unmanaged<DisplayWatcher>.fromOpaque(userInfo).takeUnretainedValue()
            watcher.handleDisplayReconfiguration(displayID: displayID, flags: flags)
        }

        let context = Unmanaged.passUnretained(self).toOpaque()
        CGDisplayRegisterReconfigurationCallback(callback, context)
        print("[macDisplayMagic] DisplayWatcher started listening for display hot-plug events.")
    }

    public func stopListening() {
        guard isListening else { return }
        isListening = false
        // Unregister callback if needed
    }

    private func handleDisplayReconfiguration(displayID: CGDirectDisplayID, flags: CGDisplayChangeSummaryFlags) {
        // We evaluate on beginConfiguration / remove / add flags
        if flags.contains(.removeFlag) || flags.contains(.disabledFlag) {
            print("[macDisplayMagic] External display removal detected (ID: \(displayID)).")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.delegate?.displayDidDisconnect()
            }
        } else if flags.contains(.addFlag) {
            print("[macDisplayMagic] External display connection detected (ID: \(displayID)).")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.delegate?.displayConfigurationDidChange()
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.delegate?.displayConfigurationDidChange()
            }
        }
    }
}
