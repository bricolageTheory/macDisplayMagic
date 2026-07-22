import Foundation

/// Display target filter for AutoMinimize rules.
public enum AutoMinimizeDisplayTarget: Codable, Equatable, Hashable {
    case anyExternal
    case unknownOnly
    case knownOnly
    case specific(hardwareID: String)

    public var title: String {
        switch self {
        case .anyExternal:
            return "Any External Monitor"
        case .unknownOnly:
            return "Unknown / New Monitors Only (Privacy Mode)"
        case .knownOnly:
            return "Known Monitors Only"
        case .specific(let hardwareID):
            let nickname = DisplayHistoryStore.shared.displayName(for: hardwareID, fallback: hardwareID)
            return "Specific Monitor: \(nickname)"
        }
    }
}

/// Data model representing an AutoMinimize rule targeting applications, window titles, and monitor conditions.
public struct AutoMinimizeRule: Identifiable, Codable, Equatable {
    public let id: UUID
    public var name: String
    public var targetBundleIDs: [String]
    public var windowTitlePattern: String
    public var displayTarget: AutoMinimizeDisplayTarget
    public var isEnabled: Bool

    public init(
        id: UUID = UUID(),
        name: String,
        targetBundleIDs: [String],
        windowTitlePattern: String = "",
        displayTarget: AutoMinimizeDisplayTarget = .anyExternal,
        isEnabled: Bool = true
    ) {
        self.id = id
        self.name = name
        self.targetBundleIDs = targetBundleIDs
        self.windowTitlePattern = windowTitlePattern
        self.displayTarget = displayTarget
        self.isEnabled = isEnabled
    }
}
