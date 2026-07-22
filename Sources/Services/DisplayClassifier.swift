import AppKit
import CoreGraphics
import Foundation

public final class DisplayClassifier {
    public static func classify(screen: NSScreen) -> DisplayCategory {
        // Built-in screen check
        if isBuiltIn(screen: screen) {
            return .builtIn
        }

        let frame = screen.frame
        let pixelWidth = frame.width * screen.backingScaleFactor
        let pixelHeight = frame.height * screen.backingScaleFactor
        let maxDim = max(pixelWidth, pixelHeight)
        let aspectRatio = max(pixelWidth, pixelHeight) / max(1.0, min(pixelWidth, pixelHeight))

        if aspectRatio >= 2.1 {
            return .ultraWide
        }

        if maxDim >= 7000 {
            return .uhd8K
        } else if maxDim >= 4800 {
            return .retina5K
        } else if maxDim >= 3400 {
            return .uhd4K
        } else if maxDim >= 1800 {
            return .fhd
        } else {
            return .standard
        }
    }

    public static func isBuiltIn(screen: NSScreen) -> Bool {
        guard let screenNumber = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID else {
            return false
        }
        return CGDisplayIsBuiltin(screenNumber) != 0
    }

    public static func displayIDString(screen: NSScreen) -> String {
        return permanentHardwareID(for: screen)
    }

    /// Permanent multi-condition EDID composite key combining Vendor ID, Model Number, Serial Number, and Commercial Name.
    public static func permanentHardwareID(for screen: NSScreen) -> String {
        guard let displayID = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID else {
            return screen.localizedName
        }

        let vendor = CGDisplayVendorNumber(displayID)
        let model = CGDisplayModelNumber(displayID)
        let serial = CGDisplaySerialNumber(displayID)
        let cleanName = screen.localizedName.replacingOccurrences(of: " ", with: "_").replacingOccurrences(of: "/", with: "_")

        return "Vendor\(vendor)_Model\(model)_SN\(serial)_\(cleanName)"
    }
}
