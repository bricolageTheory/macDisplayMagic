import AppKit
import CoreGraphics
import Foundation

/// Classifies macOS `NSScreen` instances into human-readable display categories
/// and generates stable hardware identifiers used as persistent keys in zoom rule storage.
///
/// Classification is based on the screen's physical pixel dimensions (derived from
/// `NSScreen.frame` multiplied by `backingScaleFactor`) and the aspect ratio.
/// This approach avoids relying on private APIs or EDID data directly.
public final class DisplayClassifier {

    // MARK: - Classification

    /// Classifies an `NSScreen` into a `DisplayCategory` based on pixel dimensions and aspect ratio.
    ///
    /// Detection order:
    /// 1. Built-in display (`CGDisplayIsBuiltin`)
    /// 2. UltraWide (aspect ratio ≥ 2.1)
    /// 3. 8K UHD (max pixel dimension ≥ 7000)
    /// 4. 5K Retina (max pixel dimension ≥ 4800)
    /// 5. 4K UHD (max pixel dimension ≥ 3400)
    /// 6. Full HD / 1440p (max pixel dimension ≥ 1800)
    /// 7. Standard External (everything else)
    ///
    /// - Parameter screen: The `NSScreen` to classify.
    /// - Returns: The matching `DisplayCategory`.
    public static func classify(screen: NSScreen) -> DisplayCategory {
        if isBuiltIn(screen: screen) {
            return .builtIn
        }

        let frame = screen.frame
        let pixelWidth  = frame.width  * screen.backingScaleFactor
        let pixelHeight = frame.height * screen.backingScaleFactor
        let maxDim      = max(pixelWidth, pixelHeight)
        let aspectRatio = maxDim / max(1.0, min(pixelWidth, pixelHeight))

        if aspectRatio >= 2.1   { return .ultraWide  }
        if maxDim      >= 7000  { return .uhd8K      }
        if maxDim      >= 4800  { return .retina5K   }
        if maxDim      >= 3400  { return .uhd4K      }
        if maxDim      >= 1800  { return .fhd        }
        return .standard
    }

    // MARK: - Built-in Detection

    /// Returns `true` when the given screen is the MacBook's built-in Retina display.
    ///
    /// Uses `CGDisplayIsBuiltin` via the `NSScreenNumber` device description key.
    ///
    /// - Parameter screen: The `NSScreen` to test.
    /// - Returns: `true` if the screen is the built-in display; `false` otherwise.
    public static func isBuiltIn(screen: NSScreen) -> Bool {
        guard let screenNumber = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID else {
            return false
        }
        return CGDisplayIsBuiltin(screenNumber) != 0
    }

    // MARK: - Hardware Identification

    /// Returns the permanent composite hardware identifier string for a screen.
    ///
    /// The identifier combines the EDID Vendor ID, Model Number, Serial Number,
    /// and the commercial display name into a single stable key:
    /// `"Vendor<V>_Model<M>_SN<S>_<Name>"`.
    ///
    /// This key remains consistent across macOS reboots, user sessions, and
    /// display cable reconnections for the same physical monitor.
    ///
    /// - Parameter screen: The `NSScreen` to identify.
    /// - Returns: A stable hardware ID string, or `screen.localizedName` as a fallback.
    public static func permanentHardwareID(for screen: NSScreen) -> String {
        guard let displayID = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID else {
            return screen.localizedName
        }
        let vendor    = CGDisplayVendorNumber(displayID)
        let model     = CGDisplayModelNumber(displayID)
        let serial    = CGDisplaySerialNumber(displayID)
        let cleanName = screen.localizedName
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "/", with: "_")
        return "Vendor\(vendor)_Model\(model)_SN\(serial)_\(cleanName)"
    }

    /// Convenience alias for `permanentHardwareID(for:)`.
    ///
    /// Retained for call-site compatibility where a short `displayIDString` name is preferred.
    public static func displayIDString(screen: NSScreen) -> String {
        return permanentHardwareID(for: screen)
    }
}
