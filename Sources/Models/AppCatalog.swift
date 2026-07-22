import AppKit
import Combine
import Foundation

/// Model representing a running or preset application with name, bundle identifier, and icon.
public struct AppPreset: Identifiable, Hashable {
    public var id: String { bundleID }
    public let name: String
    public let bundleID: String
    public let icon: NSImage?

    public init(name: String, bundleID: String, icon: NSImage? = nil) {
        self.name = name
        self.bundleID = bundleID
        self.icon = icon ?? AppCatalog.shared.icon(for: bundleID)
    }
}

/// Reactive catalog service managing running applications, app icon warm-caching, and preset definitions.
public final class AppCatalog: ObservableObject {
    public static let shared = AppCatalog()

    // MARK: - Published Properties
    
    @Published public var runningApps: [AppPreset] = []
    
    // MARK: - Cache & Storage
    
    private var iconCache = NSCache<NSString, NSImage>()

    // MARK: - Known Application Presets
    
    public static let knownPresets: [AppPreset] = [
        AppPreset(name: "Google Chrome", bundleID: "com.google.Chrome"),
        AppPreset(name: "Safari", bundleID: "com.apple.Safari"),
        AppPreset(name: "Mozilla Firefox", bundleID: "org.mozilla.firefox"),
        AppPreset(name: "Preview", bundleID: "com.apple.Preview"),
        AppPreset(name: "Visual Studio Code", bundleID: "com.microsoft.VSCode"),
        AppPreset(name: "Arc Browser", bundleID: "company.thebrowser.Browser"),
        AppPreset(name: "Brave Browser", bundleID: "com.brave.Browser"),
        AppPreset(name: "Microsoft Edge", bundleID: "com.microsoft.edgemac"),
        AppPreset(name: "Adobe Acrobat Reader", bundleID: "com.adobe.Reader"),
        AppPreset(name: "Slack", bundleID: "com.tinyspeck.slackmacgap")
    ]

    // MARK: - Initialization
    
    public init() {
        refreshRunningApps()
    }

    /// Pre-warms the application catalog and icon memory cache at startup.
    public static func warmUpCache() {
        shared.refreshRunningApps()
    }

    // MARK: - Application Discovery
    
    /// Queries active regular user applications running on macOS and updates the published `runningApps` list.
    public func refreshRunningApps() {
        let apps = NSWorkspace.shared.runningApplications.filter {
            $0.activationPolicy == .regular && $0.bundleIdentifier != nil && $0.bundleIdentifier != Bundle.main.bundleIdentifier
        }

        var presets: [AppPreset] = []
        for app in apps {
            guard let bundleID = app.bundleIdentifier else { continue }
            let name = app.localizedName ?? bundleID
            let appIcon = self.icon(for: bundleID)
            if !presets.contains(where: { $0.bundleID == bundleID }) {
                presets.append(AppPreset(name: name, bundleID: bundleID, icon: appIcon))
            }
        }

        let sorted = presets.sorted(by: { $0.name.lowercased() < $1.name.lowercased() })
        DispatchQueue.main.async {
            self.runningApps = sorted
        }
    }

    // MARK: - Icon Extraction & Caching
    
    /// Fetches and returns a 12x12 resized native icon for the specified bundle identifier from memory cache or workspace.
    public func icon(for bundleID: String) -> NSImage? {
        let key = bundleID as NSString
        if let cached = iconCache.object(forKey: key) {
            return cached
        }

        let rawIcon: NSImage?
        if let app = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == bundleID }), let icon = app.icon {
            rawIcon = icon
        } else if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
            rawIcon = NSWorkspace.shared.icon(forFile: url.path)
        } else {
            rawIcon = nil
        }

        if let resized = resizedIcon(rawIcon) {
            iconCache.setObject(resized, forKey: key)
            return resized
        }
        return nil
    }

    public static func icon(for bundleID: String) -> NSImage? {
        return shared.icon(for: bundleID)
    }

    /// Resolves human-readable display name for an application bundle identifier.
    public static func displayName(for bundleID: String) -> String {
        if let match = shared.runningApps.first(where: { $0.bundleID == bundleID }) {
            return match.name
        }
        if let match = knownPresets.first(where: { $0.bundleID == bundleID }) {
            return match.name
        }
        return bundleID
    }

    // MARK: - Helper Methods
    
    private func resizedIcon(_ original: NSImage?, targetSize: NSSize = NSSize(width: 12, height: 12)) -> NSImage? {
        guard let original = original else { return nil }
        guard let copy = original.copy() as? NSImage else { return nil }
        copy.size = targetSize
        return copy
    }
}
