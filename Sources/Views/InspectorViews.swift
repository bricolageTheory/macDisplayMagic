import SwiftUI

public struct MonitorInspectorView: View {
    public let details: DisplayDetails
    public var onCreateAutoMinimizeRuleForMonitor: ((String) -> Void)? = nil
    @Environment(\.dismiss) var dismiss

    public var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: details.isBuiltIn ? "laptopcomputer" : "desktopcomputer")
                    .font(.largeTitle)
                    .foregroundColor(details.isBuiltIn ? .green : .blue)

                VStack(alignment: .leading, spacing: 2) {
                    let hwID = "Vendor\(details.vendorID)_Model\(details.modelID)_SN\(details.serialNumber)_\(details.name.replacingOccurrences(of: " ", with: "_"))"
                    let displayName = DisplayHistoryStore.shared.displayName(for: hwID, fallback: details.name)
                    Text(displayName)
                        .font(.headline)
                        .bold()
                    Text(details.category.rawValue)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))

            Divider()

            // Hardware Specs Table
            VStack(spacing: 8) {
                infoRow(title: "Manufacturer:", value: details.manufacturer)
                infoRow(title: "Model Series / Number:", value: details.modelName)
                infoRow(title: "Serial Number:", value: details.serialNumber)
                if let year = details.yearOfManufacture {
                    infoRow(title: "Year of Manufacture:", value: "\(year)")
                }
                infoRow(title: "Connection Interface:", value: details.connectionType)
                infoRow(title: "Refresh Frequency:", value: details.refreshRate)
                infoRow(title: "Rotation Status:", value: details.rotationStatus)
                infoRow(title: "Display ID:", value: "\(details.displayID)")
                infoRow(title: "Native Resolution:", value: "\(details.pixelWidth) × \(details.pixelHeight) px")
                infoRow(title: "Screen Canvas:", value: "\(details.pointWidth) × \(details.pointHeight) pt")
                infoRow(title: "Retina Scale Factor:", value: "\(Int(details.scaleFactor))x (@\(Int(details.scaleFactor))x)")
                infoRow(title: "Hardware Product Code:", value: "0x\(String(details.modelID, radix: 16).uppercased()) (\(details.modelID))")
            }
            .padding(.horizontal)

            Spacer()

            VStack(spacing: 8) {
                if !details.isBuiltIn, let onCreate = onCreateAutoMinimizeRuleForMonitor {
                    Button(action: {
                        dismiss()
                        let hwID = "Vendor\(details.vendorID)_Model\(details.modelID)_SN\(details.serialNumber)_\(details.name.replacingOccurrences(of: " ", with: "_"))"
                        onCreate(hwID)
                    }) {
                        HStack {
                            Image(systemName: "arrow.down.right.and.arrow.up.left")
                            Text("Create AutoMinimize Rule for \(details.name)")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }

                Button("Close") {
                    dismiss()
                }
                .buttonStyle(.bordered)
            }
            .padding()
        }
        .frame(width: 420, height: 520)
    }

    private func infoRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .bold()
                .textSelection(.enabled)
        }
    }
}

public struct FocusedAppInspectorView: View {
    public let appName: String
    public let bundleID: String
    public let screenName: String
    public let screenCategory: DisplayCategory
    public var onCreateRule: (String) -> Void
    public var onCreateAutoMinimizeRule: ((String) -> Void)? = nil
    @Environment(\.dismiss) var dismiss

    public var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack(spacing: 12) {
                if let icon = AppCatalog.icon(for: bundleID) {
                    Image(nsImage: icon)
                        .resizable()
                        .frame(width: 36, height: 36)
                } else {
                    Image(systemName: "app.fill")
                        .font(.largeTitle)
                        .foregroundColor(.blue)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(appName)
                        .font(.headline)
                        .bold()
                    Text(bundleID.isEmpty ? "System Application" : bundleID)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .textSelection(.enabled)
                }
                Spacer()
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))

            Divider()

            // Details
            VStack(spacing: 8) {
                infoRow(title: "Application Name:", value: appName)
                infoRow(title: "Bundle Identifier:", value: bundleID.isEmpty ? "N/A" : bundleID)
                let effectiveScreenName = DisplayHistoryStore.shared.displayName(for: screenName, fallback: screenName)
                infoRow(title: "Current Monitor:", value: effectiveScreenName)
                infoRow(title: "Monitor Category:", value: screenCategory.rawValue)
            }
            .padding(.horizontal)

            Spacer()

            VStack(spacing: 8) {
                if !bundleID.isEmpty {
                    Button(action: {
                        dismiss()
                        onCreateRule(bundleID)
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Create Zoom Rule for \(appName)")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)

                    if let onCreateAuto = onCreateAutoMinimizeRule {
                        Button(action: {
                            dismiss()
                            onCreateAuto(bundleID)
                        }) {
                            HStack {
                                Image(systemName: "arrow.down.right.and.arrow.up.left")
                                Text("Create AutoMinimize Rule for \(appName)")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                }

                Button("Close") {
                    dismiss()
                }
                .buttonStyle(.plain)
            }
            .padding()
        }
        .frame(width: 360, height: 360)
    }

    private func infoRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .bold()
                .textSelection(.enabled)
        }
    }
}
