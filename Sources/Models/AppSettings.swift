import Foundation
import Combine
import ServiceManagement

public enum ClosingWindowAction: String, Codable, CaseIterable, Identifiable {
    case minimizeToMenuBar = "Keep Running in Menu Bar"
    case quitApp = "Quit Application"

    public var id: String { rawValue }
}

public final class AppSettings: ObservableObject {
    public static let shared = AppSettings()

    @Published public var showMenubarIconAtStartup: Bool {
        didSet {
            UserDefaults.standard.set(showMenubarIconAtStartup, forKey: "showMenubarIconAtStartup")
        }
    }

    @Published public var startAtLogin: Bool {
        didSet {
            UserDefaults.standard.set(startAtLogin, forKey: "startAtLogin")
            updateLaunchAtLogin(enabled: startAtLogin)
        }
    }

    @Published public var whenClosingMainWindow: ClosingWindowAction {
        didSet {
            UserDefaults.standard.set(whenClosingMainWindow.rawValue, forKey: "whenClosingMainWindow")
        }
    }

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
