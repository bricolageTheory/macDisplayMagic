import Foundation
import AppKit

public enum DisplayCategory: String, Codable, CaseIterable, Identifiable {
    case builtIn = "Built-in Retina"
    case fhd = "Full HD (1080p)"
    case uhd4K = "4K UHD"
    case retina5K = "5K Retina"
    case uhd8K = "8K UHD"
    case ultraWide = "UltraWide"
    case standard = "Standard External"

    public var id: String { rawValue }

    public var defaultZoomDelta: Int {
        switch self {
        case .builtIn: return 0 // 100%
        case .fhd: return 1     // +1 zoom step
        case .uhd4K: return 2   // +2 zoom steps (e.g. 125%/150%)
        case .retina5K: return 2 // +2 zoom steps
        case .uhd8K: return 3   // +3 zoom steps
        case .ultraWide: return 2
        case .standard: return 1
        }
    }
}
