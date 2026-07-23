import Foundation
import AppKit

/// Broad classification of an external display based on physical pixel resolution and aspect ratio.
///
/// Used by `DisplayClassifier` and the rule engine to match global zoom presets
/// against any monitor without requiring an exact hardware serial match.
///
/// Each category carries a `defaultZoomDelta` — the number of `Cmd + =` presses
/// recommended when a window is moved onto a display of that category.
public enum DisplayCategory: String, Codable, CaseIterable, Identifiable {
    /// MacBook built-in Liquid Retina display — no zoom adjustment needed.
    case builtIn = "Built-in Retina"
    /// 1080p / 1440p standard monitors (pixel width < 2560).
    case fhd = "Full HD (1080p)"
    /// 4K UHD monitors (pixel width ≈ 3840, e.g. LG 27" 4K, Dell UltraSharp 4K).
    case uhd4K = "4K UHD"
    /// 5K Retina monitors (pixel width ≈ 5120, e.g. Apple Studio Display, LG UltraFine 5K).
    case retina5K = "5K Retina"
    /// 8K UHD monitors (pixel width ≈ 7680, e.g. Dell 8K, Samsung Neo QLED 8K).
    case uhd8K = "8K UHD"
    /// UltraWide monitors with an aspect ratio ≥ 2.1 (e.g. LG 34" 21:9, Samsung Odyssey G9).
    case ultraWide = "UltraWide"
    /// Any other external display not matching the above criteria.
    case standard = "Standard External"

    public var id: String { rawValue }

    /// Default recommended number of `Cmd + =` zoom steps when a window is placed on a display of this category.
    ///
    /// Used as the fallback zoom delta when no specific per-app or per-monitor rule overrides it.
    /// A value of `0` means no zoom adjustment (built-in display baseline).
    public var defaultZoomDelta: Int {
        switch self {
        case .builtIn:   return 0  // 100% — no adjustment on MacBook Retina
        case .fhd:       return 1  // +1 step  (e.g. 110%)
        case .uhd4K:     return 2  // +2 steps (e.g. 125%)
        case .retina5K:  return 2  // +2 steps (e.g. 125%)
        case .uhd8K:     return 3  // +3 steps (e.g. 150%)
        case .ultraWide: return 2  // +2 steps
        case .standard:  return 1  // +1 step
        }
    }
}
