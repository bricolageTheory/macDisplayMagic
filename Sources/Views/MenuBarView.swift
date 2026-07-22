import SwiftUI

public struct MenuBarView: View {
    @ObservedObject var windowTracker: WindowTracker
    @ObservedObject var accessibilityManager: AccessibilityManager = AccessibilityManager.shared
    var onOpenSettings: () -> Void
    var onOpenSettingsWithPreset: ((String) -> Void)?

    @State private var inspectingMonitor: DisplayDetails? = nil
    @State private var showingAppInspector: Bool = false

    public init(
        windowTracker: WindowTracker,
        onOpenSettings: @escaping () -> Void,
        onOpenSettingsWithPreset: ((String) -> Void)? = nil
    ) {
        self.windowTracker = windowTracker
        self.onOpenSettings = onOpenSettings
        self.onOpenSettingsWithPreset = onOpenSettingsWithPreset
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "display.2")
                    .font(.title2)
                    .foregroundColor(.accentColor)
                VStack(alignment: .leading, spacing: 2) {
                    Text("macDisplayMagic")
                        .font(.headline)
                    Text("Display-Aware App Zoom Manager")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(.bottom, 4)

            Divider()

            // Accessibility Check Banner
            if !accessibilityManager.isAccessibilityTrusted {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("Accessibility Permission Required")
                            .font(.caption)
                            .bold()
                    }
                    Text("Enable Accessibility to let macDisplayMagic track window display moves and adjust zoom.")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Button("Grant Permission") {
                        _ = accessibilityManager.checkAndRequestAccessibility()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
                .padding(8)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(6)

                Divider()
            }

            // Current Active Window Context (Clickable Card)
            Button(action: {
                showingAppInspector = true
            }) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("CURRENT FOCUS")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        Spacer()
                        Image(systemName: "info.circle")
                            .font(.caption2)
                            .foregroundColor(.accentColor)
                    }

                    HStack {
                        if let icon = AppCatalog.icon(for: windowTracker.activeAppBundleID) {
                            Image(nsImage: icon)
                                .resizable()
                                .frame(width: 14, height: 14)
                        } else {
                            Image(systemName: "app.fill")
                                .foregroundColor(.blue)
                        }
                        Text(windowTracker.activeAppName)
                            .font(.subheadline)
                            .bold()
                            .foregroundColor(.primary)
                    }

                    HStack {
                        Image(systemName: windowTracker.activeScreenCategory == .builtIn ? "laptopcomputer" : "desktopcomputer")
                            .foregroundColor(windowTracker.activeScreenCategory == .builtIn ? .secondary : .blue)
                        Text("\(windowTracker.activeScreenName) (\(windowTracker.activeScreenCategory.rawValue))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.secondary.opacity(0.12))
                .cornerRadius(6)
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showingAppInspector) {
                FocusedAppInspectorView(
                    appName: windowTracker.activeAppName,
                    bundleID: windowTracker.activeAppBundleID,
                    screenName: windowTracker.activeScreenName,
                    screenCategory: windowTracker.activeScreenCategory
                ) { targetBundleID in
                    onOpenSettingsWithPreset?(targetBundleID)
                }
            }

            Divider()

            // Connected Screens Matrix (Clickable List)
            VStack(alignment: .leading, spacing: 6) {
                Text("CONNECTED MONITORS (\(NSScreen.screens.count))")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)

                ForEach(NSScreen.screens, id: \.self) { screen in
                    let details = DisplayInfoProvider.details(for: screen)
                    Button(action: {
                        inspectingMonitor = details
                    }) {
                        HStack {
                            Circle()
                                .fill(details.isBuiltIn ? Color.secondary : Color.blue)
                                .frame(width: 8, height: 8)
                            Text(screen.localizedName)
                                .font(.caption)
                                .foregroundColor(.primary)
                            Spacer()
                            Text(details.category.rawValue)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.secondary.opacity(0.15))
                                .cornerRadius(4)
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(4)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .popover(item: $inspectingMonitor) { details in
                MonitorInspectorView(details: details)
            }

            Divider()

            // Quick Actions & Rules Settings Button
            VStack(spacing: 6) {
                HStack(spacing: 8) {
                    Button(action: {
                        if let app = NSWorkspace.shared.menuBarOwningApplication {
                            ZoomEngine.shared.execute(action: .reset100, for: app.processIdentifier, appName: app.localizedName ?? "")
                        }
                    }) {
                        Label("Reset 100%", systemImage: "arrow.counterclockwise")
                            .font(.subheadline)
                            .frame(height: 22)
                    }
                    .buttonStyle(.bordered)

                    Spacer()

                    HStack(spacing: 4) {
                        Text("Zoom:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Button(action: {
                            if let app = NSWorkspace.shared.menuBarOwningApplication {
                                ZoomEngine.shared.execute(action: .zoomIn(steps: 1), for: app.processIdentifier, appName: app.localizedName ?? "")
                            }
                        }) {
                            Image(systemName: "plus")
                                .font(.subheadline.bold())
                                .frame(width: 18, height: 22)
                        }
                        .buttonStyle(.bordered)
                        .help("Zoom In (Cmd + '+')")

                        Button(action: {
                            if let app = NSWorkspace.shared.menuBarOwningApplication {
                                ZoomEngine.shared.execute(action: .zoomOut(steps: 1), for: app.processIdentifier, appName: app.localizedName ?? "")
                            }
                        }) {
                            Image(systemName: "minus")
                                .font(.subheadline.bold())
                                .frame(width: 18, height: 22)
                        }
                        .buttonStyle(.bordered)
                        .help("Zoom Out (Cmd + '-')")
                    }
                }

                Button(action: {
                    NSApp.keyWindow?.orderOut(nil)
                    onOpenSettings()
                }) {
                    HStack {
                        Spacer()
                        Image(systemName: "gearshape.fill")
                        Text("Settings")
                        Spacer()
                    }
                }
                .buttonStyle(.borderedProminent)

                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    HStack {
                        Spacer()
                        Image(systemName: "power")
                        Text("Quit macDisplayMagic")
                        Spacer()
                    }
                    .foregroundColor(.red)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(12)
        .frame(width: 280)
        .onAppear {
            accessibilityManager.refreshStatus()
        }
    }
}
