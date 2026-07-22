import Foundation

/// Data model representing a single logged display connection event.
public struct DisplayHistoryRecord: Identifiable, Codable, Equatable {
    public let id: UUID
    public let hardwareID: String
    public let defaultName: String
    public var userAssignedName: String?
    public var locationName: String
    public var locationSource: LocationSource
    public let connectedAt: Date
    public let resolution: String
    public let category: DisplayCategory

    public init(
        id: UUID = UUID(),
        hardwareID: String,
        defaultName: String,
        userAssignedName: String? = nil,
        locationName: String,
        locationSource: LocationSource = .gps,
        connectedAt: Date = Date(),
        resolution: String,
        category: DisplayCategory
    ) {
        self.id = id
        self.hardwareID = hardwareID
        self.defaultName = defaultName
        self.userAssignedName = userAssignedName
        self.locationName = locationName
        self.locationSource = locationSource
        self.connectedAt = connectedAt
        self.resolution = resolution
        self.category = category
    }

    // MARK: - Backwards Compatible Codable Implementation

    enum CodingKeys: String, CodingKey {
        case id, hardwareID, defaultName, userAssignedName, locationName, locationSource, connectedAt, resolution, category
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.hardwareID = try container.decode(String.self, forKey: .hardwareID)
        self.defaultName = try container.decode(String.self, forKey: .defaultName)
        self.userAssignedName = try container.decodeIfPresent(String.self, forKey: .userAssignedName)
        self.locationName = try container.decode(String.self, forKey: .locationName)
        self.locationSource = try container.decodeIfPresent(LocationSource.self, forKey: .locationSource) ?? .gps
        self.connectedAt = try container.decode(Date.self, forKey: .connectedAt)
        self.resolution = try container.decode(String.self, forKey: .resolution)
        self.category = try container.decode(DisplayCategory.self, forKey: .category)
    }

    /// Dynamically returns the effective display name (latest custom nickname from store if assigned, else default name).
    public var effectiveName: String {
        if let custom = DisplayHistoryStore.shared.customNamesMap[hardwareID]?.trimmingCharacters(in: .whitespacesAndNewlines), !custom.isEmpty {
            return custom
        }
        if let custom = userAssignedName?.trimmingCharacters(in: .whitespacesAndNewlines), !custom.isEmpty {
            return custom
        }
        return defaultName
    }
}
