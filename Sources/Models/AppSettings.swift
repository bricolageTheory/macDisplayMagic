import Foundation
import Combine
import ServiceManagement

/// Actions available when the user closes the main configuration window.
public enum ClosingWindowAction: String, Codable, CaseIterable, Identifiable {
    case minimizeToMenuBar = "Keep Running in Menu Bar"
    case quitApp = "Quit Application"

    public var id: String { rawValue }
}

/// Reactive singleton model managing global application preferences, launch at login, and window behavior.
public final class AppSettings: ObservableObject {
    public static let shared = AppSettings()

    // MARK: - Published Properties
    
    /// Controls whether the status item icon is shown in the macOS menu bar on startup.
    @Published public var showMenubarIconAtStartup: Bool {
        didSet {
            UserDefaults.standard.set(showMenubarIconAtStartup, forKey: "showMenubarIconAtStartup")
        }
    }

    /// Controls whether macDisplayMagic launches automatically when system starts.
    @Published public var startAtLogin: Bool {
        didSet {
            UserDefaults.standard.set(startAtLogin, forKey: "startAtLogin")
            updateLaunchAtLogin(enabled: startAtLogin)
        }
    }

    /// Action preference executed when the user closes the Settings window.
    @Published public var whenClosingMainWindow: ClosingWindowAction {
        didSet {
            UserDefaults.standard.set(whenClosingMainWindow.rawValue, forKey: "whenClosingMainWindow")
        }
    }

    // MARK: - Initialization
    
    public init() {
        self.showMenubarIconAtStartup = UserDefaults.standard.object(forKey: "showMenubarIconAtStartup") as? Bool ?? true
        self.startAtLogin = UserDefaults.standard.object(forKey: "startAtLogin") as? Bool ?? false
        if let raw = UserDefaults.standard.string(forKey: "whenClosingMainWindow"),
           let action = ClosingWindowAction(rawValue: raw) {
            self.whenClosingMainWindow = action
        } else {
            self.whenClosingMainWindow = .minimizeToMenuBar
        }
    }

    // MARK: - Launch at Login Management
    
    /// Registers or unregisters the application service with macOS ServiceManagement API.
    private func updateLaunchAtLogin(enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                    print("[macDisplayMagic] Successfully registered Launch at Login.")
                } else {
                    try SMAppService.mainApp.unregister()
                    print("[macDisplayMagic] Successfully unregistered Launch at Login.")
                }
            } catch {
                print("[macDisplayMagic] Launch at Login SMAppService update error: \(error)")
            }
        }
    }
}
