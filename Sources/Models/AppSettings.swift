import Foundation
import Combine
import ServiceManagement

/// Actions available when the user closes the main configuration window.
public enum ClosingWindowAction: String, Codable, CaseIterable, Identifiable {
    case minimizeToMenuBar = "Keep Running in Menu Bar"
    case quitApp = "Quit Application"

    public var id: String { rawValue }
}

/// Reactive singleton model managing global application preferences, launch at login, keepZooming, noZoomingDomain, and AutoMinimize.
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

    /// Controls optional continuous tab zooming (keepZooming) feature.
    @Published public var enableKeepZooming: Bool {
        didSet {
            UserDefaults.standard.set(enableKeepZooming, forKey: "enableKeepZooming")
        }
    }

    /// Controls optional domain zoom exclusion (noZoomingDomain) feature for web browsers.
    @Published public var enableNoZoomingDomain: Bool {
        didSet {
            UserDefaults.standard.set(enableNoZoomingDomain, forKey: "enableNoZoomingDomain")
        }
    }

    /// List of domain names excluded from automatic zooming (e.g. netflix.com, youtube.com).
    @Published public var noZoomDomains: [String] {
        didSet {
            UserDefaults.standard.set(noZoomDomains, forKey: "noZoomDomains")
        }
    }

    /// Controls optional AutoMinimize feature on external monitor connection.
    @Published public var enableAutoMinimize: Bool {
        didSet {
            UserDefaults.standard.set(enableAutoMinimize, forKey: "enableAutoMinimize")
        }
    }

    /// List of configured AutoMinimize rules.
    @Published public var autoMinimizeRules: [AutoMinimizeRule] {
        didSet {
            saveAutoMinimizeRules()
        }
    }

    /// Controls ADA accessibility scaling for the main status menu (85% to 160%).
    @Published public var menuScaleFactor: Double {
        didSet {
            UserDefaults.standard.set(menuScaleFactor, forKey: "menuScaleFactor")
        }
    }

    private let autoMinimizeStorageKey = "macDisplayMagic.autoMinimizeRules"

    // MARK: - Initialization
    
    public init() {
        self.menuScaleFactor = UserDefaults.standard.object(forKey: "menuScaleFactor") as? Double ?? 1.0
        self.showMenubarIconAtStartup = UserDefaults.standard.object(forKey: "showMenubarIconAtStartup") as? Bool ?? true
        self.startAtLogin = UserDefaults.standard.object(forKey: "startAtLogin") as? Bool ?? false
        if let raw = UserDefaults.standard.string(forKey: "whenClosingMainWindow"),
           let action = ClosingWindowAction(rawValue: raw) {
            self.whenClosingMainWindow = action
        } else {
            self.whenClosingMainWindow = .minimizeToMenuBar
        }

        self.enableKeepZooming = UserDefaults.standard.object(forKey: "enableKeepZooming") as? Bool ?? false
        self.enableNoZoomingDomain = UserDefaults.standard.object(forKey: "enableNoZoomingDomain") as? Bool ?? true
        self.noZoomDomains = UserDefaults.standard.array(forKey: "noZoomDomains") as? [String] ?? [
            "netflix.com",
            "disneyplus.com",
            "youtube.com",
            "hulu.com",
            "primevideo.com",
            "twitch.tv"
        ]

        self.enableAutoMinimize = UserDefaults.standard.object(forKey: "enableAutoMinimize") as? Bool ?? false
        if let data = UserDefaults.standard.data(forKey: autoMinimizeStorageKey),
           let decoded = try? JSONDecoder().decode([AutoMinimizeRule].self, from: data) {
            self.autoMinimizeRules = decoded
        } else {
            self.autoMinimizeRules = [
                AutoMinimizeRule(
                    name: "Minimize Music & Social Apps",
                    targetBundleIDs: ["com.apple.Music", "com.spotify.client", "com.slack.Slack"],
                    windowTitlePattern: "",
                    isEnabled: true
                )
            ]
        }
    }

    public func saveAutoMinimizeRules() {
        if let data = try? JSONEncoder().encode(autoMinimizeRules) {
            UserDefaults.standard.set(data, forKey: autoMinimizeStorageKey)
        }
    }

    // MARK: - Domain Exclusion Helper Methods
    
    public func addNoZoomDomain(_ domain: String) {
        let clean = domain.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !clean.isEmpty, !noZoomDomains.contains(clean) else { return }
        noZoomDomains.append(clean)
    }

    public func removeNoZoomDomain(_ domain: String) {
        noZoomDomains.removeAll(where: { $0.lowercased() == domain.lowercased() })
    }

    // MARK: - Launch at Login Management
    
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
