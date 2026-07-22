import SwiftUI
import AppKit

/// Application Delegate for macDisplayMagic handling app lifecycle, single instance enforcement,
/// display reconfiguration events, and settings window management.
final class AppDelegate: NSObject, NSApplicationDelegate, DisplayWatcherDelegate {
    
    // MARK: - Properties
    
    let windowTracker = WindowTracker()
    let displayWatcher = DisplayWatcher()
    var settingsWindow: NSWindow?

    // MARK: - Application Lifecycle
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        enforceSingleInstance()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("[macDisplayMagic] Application started successfully.")

        displayWatcher.delegate = self
        displayWatcher.startListening()
        windowTracker.startTracking()

        _ = AccessibilityManager.shared.checkAndRequestAccessibility()
        NotificationService.shared.requestAuthorization()
        LocationService.shared.requestAuthorization()
        DisplayHistoryStore.shared.syncCurrentlyConnectedDisplays()
        AppCatalog.warmUpCache()
    }

    // MARK: - Single Instance Guard
    
    /// Enforces single-instance execution by checking running applications matching bundle ID or process name.
    private func enforceSingleInstance() {
        let currentApp = NSRunningApplication.current
        let runningApps = NSWorkspace.shared.runningApplications.filter { app in
            let matchesBundleID = currentApp.bundleIdentifier != nil && app.bundleIdentifier == currentApp.bundleIdentifier
            let matchesName = app.localizedName == "macDisplayMagic"
            return (matchesBundleID || matchesName) && app.processIdentifier != currentApp.processIdentifier
        }

        if let existingApp = runningApps.first {
            print("[macDisplayMagic] Another instance of macDisplayMagic is already running (PID: \(existingApp.processIdentifier)). Activating existing instance and exiting...")
            existingApp.activate(options: [.activateIgnoringOtherApps])
            exit(0)
        }
    }

    // MARK: - DisplayWatcherDelegate Methods
    
    func displayDidConnect(screen: NSScreen) {
        DisplayInfoProvider.invalidateCache()
        print("[macDisplayMagic] Display connected: \(screen.localizedName)")
        DisplayHistoryStore.shared.logConnection(screen: screen)
        AutoMinimizeService.shared.executeAutoMinimize()
        windowTracker.checkActiveWindowScreen()
    }

    func displayDidDisconnect() {
        DisplayInfoProvider.invalidateCache()
        let zoomedPIDs = windowTracker.getZoomedPIDs()
        print("[macDisplayMagic] External Display disconnected. Resetting \(zoomedPIDs.count) zoomed application(s)...")
        ZoomEngine.shared.resetAllRunningAppsToDefault(runningApps: NSWorkspace.shared.runningApplications, targetPIDs: zoomedPIDs)
        windowTracker.clearZoomedStates()
    }

    func displayConfigurationDidChange() {
        DisplayInfoProvider.invalidateCache()
        print("[macDisplayMagic] Display configuration updated.")
        for screen in NSScreen.screens {
            let details = DisplayInfoProvider.details(for: screen)
            if !details.isBuiltIn {
                DisplayHistoryStore.shared.logConnection(screen: screen)
            }
        }
        AutoMinimizeService.shared.executeAutoMinimize()
        windowTracker.checkActiveWindowScreen()
    }

    // MARK: - Settings Window Management
    
    /// Opens or focuses the main Settings & Configuration window.
    func openSettingsWindow(presetBundleID: String? = nil, presetAutoMinimizeAppID: String? = nil, presetAutoMinimizeHardwareID: String? = nil) {
        if let keyWindow = NSApp.keyWindow, keyWindow != settingsWindow {
            keyWindow.orderOut(nil)
        }

        let view = RulesConfigView(
            presetBundleID: presetBundleID,
            presetAutoMinimizeAppID: presetAutoMinimizeAppID,
            presetAutoMinimizeHardwareID: presetAutoMinimizeHardwareID
        )
        let hostingController = NSHostingController(rootView: view)

        if settingsWindow == nil {
            let window = NSWindow(contentViewController: hostingController)
            window.title = "macDisplayMagic Settings"
            window.styleMask = NSWindow.StyleMask([.titled, .closable, .resizable, .miniaturizable])
            window.center()
            window.isReleasedWhenClosed = false
            window.delegate = self
            settingsWindow = window
        } else {
            settingsWindow?.contentViewController = hostingController
        }

        let topLevel = NSWindow.Level(Int(NSWindow.Level.statusBar.rawValue) + 1)
        settingsWindow?.level = topLevel
        settingsWindow?.makeKeyAndOrderFront(nil)
        settingsWindow?.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)
    }
}

// MARK: - NSWindowDelegate

extension AppDelegate: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        // Closing the settings window simply closes the settings window. The app continues running in the menu bar.
    }
}

// MARK: - Main Application Entry Point

@main
struct MacDisplayMagicApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra("macDisplayMagic", systemImage: "display.2") {
            MenuBarView(
                windowTracker: appDelegate.windowTracker,
                onOpenSettings: {
                    appDelegate.openSettingsWindow()
                },
                onOpenSettingsWithPreset: { presetBundleID in
                    appDelegate.openSettingsWindow(presetBundleID: presetBundleID)
                },
                onOpenAutoMinimizePresetApp: { bundleID in
                    appDelegate.openSettingsWindow(presetAutoMinimizeAppID: bundleID)
                },
                onOpenAutoMinimizePresetMonitor: { hardwareID in
                    appDelegate.openSettingsWindow(presetAutoMinimizeHardwareID: hardwareID)
                }
            )
        }
        .menuBarExtraStyle(.window)
    }
}
