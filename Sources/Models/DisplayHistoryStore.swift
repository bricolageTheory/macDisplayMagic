import AppKit
import Combine
import Foundation

/// Reactive store managing persistent monitor connection history logs and custom display nicknames.
public final class DisplayHistoryStore: ObservableObject {
    public static let shared = DisplayHistoryStore()

    // MARK: - Published Properties
    
    /// Connection history log entries
    @Published public var historyRecords: [DisplayHistoryRecord] = [] {
        didSet {
            saveHistory()
        }
    }

    /// Persistent map of hardwareID -> customNickname assigned by user
    @Published public var customNamesMap: [String: String] = [:] {
        didSet {
            saveCustomNames()
        }
    }

    private let historyStorageKey = "macDisplayMagic.historyRecords"
    private let customNamesStorageKey = "macDisplayMagic.customNamesMap"

    public init() {
        loadData()
    }

    // MARK: - Persistence Methods
    
    public func loadData() {
        if let data = UserDefaults.standard.data(forKey: historyStorageKey),
           let decoded = try? JSONDecoder().decode([DisplayHistoryRecord].self, from: data) {
            self.historyRecords = decoded
        }
        if let data = UserDefaults.standard.data(forKey: customNamesStorageKey),
           let decoded = try? JSONDecoder().decode([String: String].self, from: data) {
            self.customNamesMap = decoded
        }
    }

    public func saveHistory() {
        if let data = try? JSONEncoder().encode(historyRecords) {
            UserDefaults.standard.set(data, forKey: historyStorageKey)
        }
    }

    public func saveCustomNames() {
        if let data = try? JSONEncoder().encode(customNamesMap) {
            UserDefaults.standard.set(data, forKey: customNamesStorageKey)
        }
    }

    // MARK: - Custom Naming Methods
    
    /// Returns the assigned nickname for a display hardware ID, or fallback name.
    public func displayName(for hardwareID: String, fallback: String) -> String {
        if let custom = customNamesMap[hardwareID]?.trimmingCharacters(in: .whitespacesAndNewlines), !custom.isEmpty {
            return custom
        }
        return fallback
    }

    /// Checks if a display hardware ID is known (previously saved in history or custom names).
    public func isKnownMonitor(hardwareID: String) -> Bool {
        if customNamesMap[hardwareID] != nil { return true }
        return historyRecords.contains(where: { $0.hardwareID == hardwareID })
    }

    /// Sets or clears a custom nickname for a display hardware ID.
    public func setCustomName(_ name: String, for hardwareID: String) {
        let clean = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if clean.isEmpty {
            customNamesMap.removeValue(forKey: hardwareID)
        } else {
            customNamesMap[hardwareID] = clean
        }

        // Update existing history records
        for i in 0..<historyRecords.count {
            if historyRecords[i].hardwareID == hardwareID {
                historyRecords[i].userAssignedName = clean.isEmpty ? nil : clean
            }
        }
    }

    // MARK: - Connection Logger
    
    /// Synchronizes history for all currently connected external displays on startup.
    public func syncCurrentlyConnectedDisplays() {
        for screen in NSScreen.screens {
            let details = DisplayInfoProvider.details(for: screen)
            if !details.isBuiltIn {
                logConnection(screen: screen)
            }
        }
    }

    /// Logs an external display connection event with physical location tag.
    public func logConnection(screen: NSScreen) {
        let details = DisplayInfoProvider.details(for: screen)
        guard !details.isBuiltIn else { return } // Only log external display connections

        let hardwareID = DisplayClassifier.displayIDString(screen: screen)
        let defaultName = details.name
        let resolution = "\(Int(screen.frame.width))x\(Int(screen.frame.height))"
        let category = details.category
        let customName = customNamesMap[hardwareID]

        // Avoid duplicate logging if logged within the last 10 seconds
        if let latest = historyRecords.first, latest.hardwareID == hardwareID, abs(latest.connectedAt.timeIntervalSinceNow) < 10 {
            return
        }

        LocationService.shared.fetchCurrentLocationResult { [weak self] locationName, source in
            guard let self = self else { return }
            let record = DisplayHistoryRecord(
                hardwareID: hardwareID,
                defaultName: defaultName,
                userAssignedName: customName,
                locationName: locationName,
                locationSource: source,
                connectedAt: Date(),
                resolution: resolution,
                category: category
            )
            
            DispatchQueue.main.async {
                self.historyRecords.insert(record, at: 0)
                // Cap history log to latest 100 entries
                if self.historyRecords.count > 100 {
                    self.historyRecords = Array(self.historyRecords.prefix(100))
                }
            }
        }
    }

    /// Replaces any "Location Pending Approval" tags in history records once location is resolved.
    public func updatePendingLocationRecords(with locationName: String, source: LocationSource = .gps) {
        var updated = false
        for i in 0..<historyRecords.count {
            if historyRecords[i].locationName.contains("Pending") || historyRecords[i].locationName.contains("Unknown") || historyRecords[i].locationSource == .pending {
                historyRecords[i].locationName = locationName
                historyRecords[i].locationSource = source
                updated = true
            }
        }
        if updated {
            objectWillChange.send()
            saveHistory()
        }
    }

    public func clearHistory() {
        historyRecords.removeAll()
    }
}
