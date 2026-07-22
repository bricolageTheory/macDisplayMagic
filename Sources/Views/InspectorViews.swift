import SwiftUI

public struct MonitorInspectorView: View {
    public let details: DisplayDetails
    @Environment(\.dismiss) var dismiss

    public var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: details.isBuiltIn ? "laptopcomputer" : "desktopcomputer")
                    .font(.largeTitle)
                    .foregroundColor(details.isBuiltIn ? .green : .blue)

                VStack(alignment: .leading, spacing: 2) {
                    Text(details.name)
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

            HStack {
                Spacer()
                Button("Close") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .frame(width: 420, height: 490)
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
                infoRow(title: "Current Monitor:", value: screenName)
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
                }

                Button("Close") {
                    dismiss()
                }
                .buttonStyle(.bordered)
            }
            .padding()
        }
        .frame(width: 360, height: 320)
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
