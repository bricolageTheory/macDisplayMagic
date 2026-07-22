import Foundation

public enum ZoomAction: Codable, Equatable, Hashable, CustomStringConvertible {
    case reset100
    case zoomIn(steps: Int)
    case zoomOut(steps: Int)

    public var description: String {
        switch self {
        case .reset100:
            return "Reset to 100% (Cmd + 0)"
        case .zoomIn(let steps):
            return "Zoom In +\(steps) (Cmd + '+')"
        case .zoomOut(let steps):
            return "Zoom Out -\(steps) (Cmd + '-')"
        }
    }
}

public struct ZoomRule: Identifiable, Codable, Equatable {
    public var id: UUID
    public var name: String
    public var appBundleID: String?              // nil = All Apps (Global)
    public var displayCategory: DisplayCategory? // nil = Any Category
    public var targetMonitorModel: String?       // nil = Any Model in Category
    public var targetMonitorSerial: String?      // nil = Any Serial
    public var action: ZoomAction
    public var isEnabled: Bool

    public init(
        id: UUID = UUID(),
        name: String,
        appBundleID: String? = nil,
        displayCategory: DisplayCategory? = nil,
        targetMonitorModel: String? = nil,
        targetMonitorSerial: String? = nil,
        action: ZoomAction,
        isEnabled: Bool = true
    ) {
        self.id = id
        self.name = name
        self.appBundleID = appBundleID
        self.displayCategory = displayCategory
        self.targetMonitorModel = targetMonitorModel
        self.targetMonitorSerial = targetMonitorSerial
        self.action = action
        self.isEnabled = isEnabled
    }
}
