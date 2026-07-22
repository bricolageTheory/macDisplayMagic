import Foundation
import Combine
import AppKit

public final class RulesStore: ObservableObject {
    public static let shared = RulesStore()

    @Published public var rules: [ZoomRule] = [] {
        didSet {
            saveRules()
        }
    }

    private let storageKey = "macDisplayMagic.userRules"

    public init() {
        loadRules()
    }

    public func loadRules() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([ZoomRule].self, from: data) {
            self.rules = decoded
        } else {
            self.rules = Self.defaultRules()
        }
    }

    public func saveRules() {
        if let data = try? JSONEncoder().encode(rules) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    public static func defaultRules() -> [ZoomRule] {
        return [
            ZoomRule(
                name: "MacBook Built-in Screen Reset",
                displayCategory: .builtIn,
                action: .reset100,
                isEnabled: true
            ),
            ZoomRule(
                name: "4K Displays Global Zoom",
                displayCategory: .uhd4K,
                action: .zoomIn(steps: 2),
                isEnabled: true
            ),
            ZoomRule(
                name: "8K Displays Global Zoom",
                displayCategory: .uhd8K,
                action: .zoomIn(steps: 3),
                isEnabled: true
            ),
            ZoomRule(
                name: "5K Retina Displays Zoom",
                displayCategory: .retina5K,
                action: .zoomIn(steps: 2),
                isEnabled: true
            ),
            ZoomRule(
                name: "UltraWide Displays Zoom",
                displayCategory: .ultraWide,
                action: .zoomIn(steps: 2),
                isEnabled: true
            )
        ]
    }

    /// Evaluates rules according to decision hierarchy:
    /// 1. App + Monitor Serial
    /// 2. App + Monitor Model
    /// 3. App + Display Resolution Category
    /// 4. Global + Monitor Serial
    /// 5. Global + Monitor Model
    /// 6. Global + Display Resolution Category
    public func evaluateRule(appBundleID: String?, displayCategory: DisplayCategory, screen: NSScreen? = nil) -> ZoomAction? {
        let activeRules = rules.filter { $0.isEnabled }
        let details = screen != nil ? DisplayInfoProvider.details(for: screen!) : nil

        let targetSerial = details?.serialNumber
        let targetModel = details?.modelName

        // 1. App + Monitor Serial
        if let appID = appBundleID, let serial = targetSerial, !serial.isEmpty, serial != "N/A",
           let match = activeRules.first(where: { $0.appBundleID == appID && $0.targetMonitorSerial == serial }) {
            return match.action
        }

        // 2. App + Monitor Model
        if let appID = appBundleID, let model = targetModel, !model.isEmpty,
           let match = activeRules.first(where: { $0.appBundleID == appID && matchesModel(ruleModel: $0.targetMonitorModel, targetModel: model) }) {
            return match.action
        }

        // 3. App + Resolution Category
        if let appID = appBundleID,
           let match = activeRules.first(where: { $0.appBundleID == appID && $0.targetMonitorSerial == nil && $0.targetMonitorModel == nil && $0.displayCategory == displayCategory }) {
            return match.action
        }

        // 4. Global + Monitor Serial
        if let serial = targetSerial, !serial.isEmpty, serial != "N/A",
           let match = activeRules.first(where: { $0.appBundleID == nil && $0.targetMonitorSerial == serial }) {
            return match.action
        }

        // 5. Global + Monitor Model
        if let model = targetModel, !model.isEmpty,
           let match = activeRules.first(where: { $0.appBundleID == nil && matchesModel(ruleModel: $0.targetMonitorModel, targetModel: model) }) {
            return match.action
        }

        // 6. Global + Resolution Category
        if let match = activeRules.first(where: { $0.appBundleID == nil && $0.targetMonitorSerial == nil && $0.targetMonitorModel == nil && $0.displayCategory == displayCategory }) {
            return match.action
        }

        return nil
    }

    private func matchesModel(ruleModel: String?, targetModel: String) -> Bool {
        guard let ruleModel = ruleModel, !ruleModel.isEmpty else { return false }
        return targetModel.localizedCaseInsensitiveContains(ruleModel) || ruleModel.localizedCaseInsensitiveContains(targetModel)
    }
}
