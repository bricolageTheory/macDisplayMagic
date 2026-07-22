import Foundation

/// Action to execute on target application windows.
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

/// Data model representing a zoom rule matching application, display category, hardware model, or serial number.
public struct ZoomRule: Identifiable, Codable, Equatable {
    public var id: UUID
    public var name: String
    /// Target application bundle ID (`nil` matches All Applications).
    public var appBundleID: String?
    /// Display category filter (`nil` matches Any Display Category).
    public var displayCategory: DisplayCategory?
    /// Hardware monitor model name filter (`nil` matches Any Model).
    public var targetMonitorModel: String?
    /// Hardware monitor serial number filter (`nil` matches Any Serial).
    public var targetMonitorSerial: String?
    /// Action to execute when rule triggers.
    public var action: ZoomAction
    /// Toggle switch state.
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
