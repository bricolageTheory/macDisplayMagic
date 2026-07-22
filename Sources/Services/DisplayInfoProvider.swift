import AppKit
import CoreGraphics
import Foundation
import IOKit

public struct DisplayDetails: Identifiable, Hashable {
    public var id: String { "\(displayID)" }
    public let name: String
    public let category: DisplayCategory
    public let displayID: CGDirectDisplayID
    public let pixelWidth: Int
    public let pixelHeight: Int
    public let pointWidth: Int
    public let pointHeight: Int
    public let scaleFactor: CGFloat
    public let isBuiltIn: Bool
    public let vendorID: UInt32
    public let modelID: UInt32
    public let manufacturer: String
    public let modelName: String
    public let serialNumber: String
    public let yearOfManufacture: Int?
    public let connectionType: String
    public let refreshRate: String
    public let rotationStatus: String

    public var resolutionString: String {
        return "\(pixelWidth) × \(pixelHeight) (\(Int(scaleFactor))x Retina Scale)"
    }
}

public final class DisplayInfoProvider {
    private static var detailsCache: [CGDirectDisplayID: DisplayDetails] = [:]

    public static func invalidateCache() {
        detailsCache.removeAll()
    }

    public static func details(for screen: NSScreen) -> DisplayDetails {
        let screenNumber = (screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID) ?? 0

        // 0ms instant RAM cache return
        if let cached = detailsCache[screenNumber] {
            return cached
        }

        let category = DisplayClassifier.classify(screen: screen)

        let pointWidth = Int(screen.frame.width)
        let pointHeight = Int(screen.frame.height)
        let scale = screen.backingScaleFactor
        let pixelWidth = Int(screen.frame.width * scale)
        let pixelHeight = Int(screen.frame.height * scale)

        let isBuiltIn = CGDisplayIsBuiltin(screenNumber) != 0
        let vendorID = CGDisplayVendorNumber(screenNumber)
        let modelID = CGDisplayModelNumber(screenNumber)
        let manufacturer = lookupVendorName(vendorID: vendorID, isBuiltIn: isBuiltIn)

        let mode = CGDisplayCopyDisplayMode(screenNumber)
        let rawRate = mode?.refreshRate ?? 0
        let refreshRate: String
        if rawRate >= 120 {
            refreshRate = "\(Int(rawRate)) Hz (ProMotion)"
        } else if rawRate > 0 {
            refreshRate = "\(Int(rawRate)) Hz"
        } else {
            refreshRate = "60 Hz (Nominal)"
        }

        let rotationAngle = CGDisplayRotation(screenNumber)
        let rotationStatus: String
        if isBuiltIn {
            rotationStatus = "Not Supported (Built-in Display)"
        } else {
            let angleInt = Int(rotationAngle)
            switch angleInt {
            case 90:
                rotationStatus = "Supported (Current: Portrait 90°)"
            case 180:
                rotationStatus = "Supported (Current: Inverted 180°)"
            case 270:
                rotationStatus = "Supported (Current: Portrait 270°)"
            default:
                rotationStatus = "Supported (Current: Standard 0°)"
            }
        }

        let extended = fetchIOKitInfo(vendorID: vendorID, modelID: modelID, isBuiltIn: isBuiltIn)

        let connectionType: String
        if isBuiltIn {
            connectionType = "Internal Apple Display Bus"
        } else if let dfp = extended.dfpType {
            if dfp.uppercased().contains("DP") {
                connectionType = "USB-C / DisplayPort (DP)"
            } else if dfp.uppercased().contains("HDMI") {
                connectionType = "HDMI Port"
            } else {
                connectionType = "External \(dfp)"
            }
        } else {
            connectionType = "External Digital Connector"
        }

        let result = DisplayDetails(
            name: screen.localizedName,
            category: category,
            displayID: screenNumber,
            pixelWidth: pixelWidth,
            pixelHeight: pixelHeight,
            pointWidth: pointWidth,
            pointHeight: pointHeight,
            scaleFactor: scale,
            isBuiltIn: isBuiltIn,
            vendorID: vendorID,
            modelID: modelID,
            manufacturer: manufacturer,
            modelName: extended.modelName,
            serialNumber: extended.serialNumber,
            yearOfManufacture: extended.yearOfManufacture,
            connectionType: connectionType,
            refreshRate: refreshRate,
            rotationStatus: rotationStatus
        )

        detailsCache[screenNumber] = result
        return result
    }

    private static func fetchIOKitInfo(vendorID: UInt32, modelID: UInt32, isBuiltIn: Bool) -> (modelName: String, serialNumber: String, yearOfManufacture: Int?, dfpType: String?) {
        if isBuiltIn {
            return ("Apple Built-in Retina Display", "N/A (Built-in)", nil, "Internal")
        }

        var iterator = io_iterator_t()
        let matching = IOServiceMatching("IOService")
        IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator)

        var service = IOIteratorNext(iterator)
        var foundSinkID: String?
        var foundProductName: String?
        var foundSerial: String?
        var foundYear: Int?
        var foundDFP: String?

        while service != 0 {
            var properties: Unmanaged<CFMutableDictionary>?
            if IORegistryEntryCreateCFProperties(service, &properties, kCFAllocatorDefault, 0) == KERN_SUCCESS,
               let dict = properties?.takeRetainedValue() as? [String: Any] {

                if let meta = dict["Metadata"] as? [String: Any] {
                    if let sinkID = meta["SinkDeviceID"] as? String, !sinkID.isEmpty {
                        foundSinkID = sinkID
                    }
                    if let dfpDesc = meta["DFP Type Description"] as? String, !dfpDesc.isEmpty {
                        foundDFP = dfpDesc
                    }
                }

                if let attrs = dict["DisplayAttributes"] as? [String: Any],
                   let productAttrs = attrs["ProductAttributes"] as? [String: Any] {

                    var isTarget = false
                    if let pidNumber = productAttrs["ProductID"] as? NSNumber {
                        if pidNumber.uint32Value == modelID {
                            isTarget = true
                        }
                    }

                    if isTarget {
                        if let serial = productAttrs["AlphanumericSerialNumber"] as? String {
                            foundSerial = serial
                        }
                        if let year = productAttrs["YearOfManufacture"] as? Int {
                            foundYear = year
                        }
                        if let pName = productAttrs["ProductName"] as? String {
                            foundProductName = pName
                        }
                    }
                }
            }
            service = IOIteratorNext(iterator)
        }
        IOObjectRelease(iterator)

        let resolvedVariants = resolveModelVariants(sinkID: foundSinkID)
        let finalModel: String
        if let pName = foundProductName, !pName.isEmpty {
            if let variants = resolvedVariants {
                finalModel = "\(pName) (\(variants))"
            } else {
                finalModel = pName
            }
        } else {
            finalModel = resolvedVariants ?? "Model 0x\(String(modelID, radix: 16).uppercased())"
        }

        let finalSerial = foundSerial ?? "N/A"
        return (finalModel, finalSerial, foundYear, foundDFP)
    }

    private static func resolveModelVariants(sinkID: String?) -> String? {
        guard let sink = sinkID, !sink.isEmpty else { return nil }

        let knownVariants: [String: String] = [
            "32UN88": "32UP83A / 32UN880 / 32UN88",
            "32UN880": "32UP83A / 32UN880 / 32UN88",
            "27UK850": "27UK850 / 27UL850 / 27UP850",
            "27UL850": "27UL850 / 27UP850",
            "27GP950": "27GP950 / 27GN950 / 27GP95B",
            "34WK95U": "34WK95U / 34BK95U",
            "U2720Q": "U2720Q / U2720QM",
            "U2723QE": "U2723QE / U2723QX",
            "U3223QE": "U3223QE / U3223QX",
            "S2722QC": "S2722QC / S2722Q",
            "PA278CV": "PA278CV / PA278QV"
        ]

        return knownVariants[sink] ?? sink
    }

    private static func lookupVendorName(vendorID: UInt32, isBuiltIn: Bool) -> String {
        if isBuiltIn || vendorID == 0x0610 {
            return "Apple Inc."
        }

        switch vendorID {
        case 0x1E6D:
            return "LG Electronics"
        case 0x10AC:
            return "Dell Inc."
        case 0x4C2D:
            return "Samsung Electronics"
        case 0x0469:
            return "ASUS"
        case 0x05E3:
            return "BenQ"
        case 0x38A3:
            return "HP Inc."
        case 0x15C3:
            return "Acer"
        default:
            return "External Display (Vendor 0x\(String(vendorID, radix: 16).uppercased()))"
        }
    }
}
