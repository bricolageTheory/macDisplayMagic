import SwiftUI

public struct MenuBarView: View {
    @ObservedObject var windowTracker: WindowTracker
    @ObservedObject var historyStore = DisplayHistoryStore.shared
    @ObservedObject var appSettings = AppSettings.shared
    @ObservedObject var accessibilityManager: AccessibilityManager = AccessibilityManager.shared
    var onOpenSettings: () -> Void
    var onOpenSettingsWithPreset: ((String) -> Void)?
    var onOpenAutoMinimizePresetApp: ((String) -> Void)?
    var onOpenAutoMinimizePresetMonitor: ((String) -> Void)?

    @State private var inspectingMonitor: DisplayDetails? = nil
    @State private var showingAppInspector: Bool = false

    public init(
        windowTracker: WindowTracker,
        onOpenSettings: @escaping () -> Void,
        onOpenSettingsWithPreset: ((String) -> Void)? = nil,
        onOpenAutoMinimizePresetApp: ((String) -> Void)? = nil,
        onOpenAutoMinimizePresetMonitor: ((String) -> Void)? = nil
    ) {
        self.windowTracker = windowTracker
        self.onOpenSettings = onOpenSettings
        self.onOpenSettingsWithPreset = onOpenSettingsWithPreset
        self.onOpenAutoMinimizePresetApp = onOpenAutoMinimizePresetApp
        self.onOpenAutoMinimizePresetMonitor = onOpenAutoMinimizePresetMonitor
    }

    private var p: MenuScaleProfile {
        MenuScaleProfile.profile(for: appSettings.menuScaleFactor)
    }

    private static let scaleSteps: [Double] = [0.75, 0.85, 0.95, 1.00, 1.12, 1.25, 1.38, 1.50, 1.65, 1.85, 2.10]

    private func zoomOutMenu() {
        let current = appSettings.menuScaleFactor
        if let idx = Self.scaleSteps.firstIndex(where: { $0 >= current - 0.03 }), idx > 0 {
            appSettings.menuScaleFactor = Self.scaleSteps[idx - 1]
        } else if let first = Self.scaleSteps.first {
            appSettings.menuScaleFactor = first
        }
    }

    private func zoomInMenu() {
        let current = appSettings.menuScaleFactor
        if let idx = Self.scaleSteps.lastIndex(where: { $0 <= current + 0.03 }), idx < Self.scaleSteps.count - 1 {
            appSettings.menuScaleFactor = Self.scaleSteps[idx + 1]
        } else if let last = Self.scaleSteps.last {
            appSettings.menuScaleFactor = last
        }
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: p.innerSpacing) {
            // Header
            HStack(alignment: .top) {
                Image(systemName: "display.2")
                    .font(.system(size: p.fontTitle + 5))
                    .foregroundColor(.accentColor)
                VStack(alignment: .leading, spacing: 1) {
                    Text("macDisplayMagic")
                        .font(.system(size: p.fontTitle, weight: .bold))
                        .lineLimit(1)
                    Text("Display-Aware")
                        .font(.system(size: p.fontSubtitle))
                        .lineLimit(1)
                        .foregroundColor(.secondary)
                    Text("Application Zoom Manager")
                        .font(.system(size: p.fontSubtitle))
                        .lineLimit(1)
                        .foregroundColor(.secondary)
                }
                .layoutPriority(1)
                .fixedSize(horizontal: true, vertical: false)
                Spacer()

                // 2-Line Vertical ADA Menu Size [-] / [+] Scaling Block (Center-Aligned)
                VStack(alignment: .center, spacing: 2) {
                    Text("Menu Size:")
                        .font(.system(size: p.fontCaption, weight: .medium))
                        .lineLimit(1)
                        .foregroundColor(.secondary)

                    HStack(spacing: 2) {
                        Button(action: {
                            zoomOutMenu()
                        }) {
                            Image(systemName: "minus")
                                .font(.system(size: p.fontCaption - 1, weight: .bold))
                                .frame(width: p.menuSizeButtonWidth, height: p.menuSizeButtonHeight)
                        }
                        .buttonStyle(.bordered)
                        .disabled(appSettings.menuScaleFactor <= 0.76)
                        .help("Reduce Menu Size (ADA Accessibility)")

                        Button(action: {
                            zoomInMenu()
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: p.fontCaption - 1, weight: .bold))
                                .frame(width: p.menuSizeButtonWidth, height: p.menuSizeButtonHeight)
                        }
                        .buttonStyle(.bordered)
                        .disabled(appSettings.menuScaleFactor >= 2.08)
                        .help("Enlarge Menu Size (ADA Accessibility)")
                    }
                }
            }
            .padding(.bottom, 2)

            Divider()

            // Accessibility Check Banner
            if !accessibilityManager.isAccessibilityTrusted {
                VStack(alignment: .leading, spacing: p.innerSpacing - 2) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("Accessibility Permission Required")
                            .font(.system(size: p.fontBody, weight: .bold))
                    }
                    Text("Enable Accessibility to let macDisplayMagic track window display moves and adjust zoom.")
                        .font(.system(size: p.fontCaption))
                        .foregroundColor(.secondary)

                    Button("Grant Permission") {
                        _ = accessibilityManager.checkAndRequestAccessibility()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
                .padding(p.innerSpacing - 2)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(6)

                Divider()
            }

            // Focused App & Zoom Control Card
            VStack(alignment: .leading, spacing: p.innerSpacing - 3) {
                Text("FOCUSED APP & ZOOM CONTROL")
                    .font(.system(size: p.fontSectionHeader, weight: .semibold))
                    .foregroundColor(.secondary)

                VStack(alignment: .leading, spacing: p.innerSpacing - 2) {
                    // Clickable 3-Level Focus Hierarchy Tree
                    Button(action: {
                        showingAppInspector = true
                    }) {
                        VStack(alignment: .leading, spacing: p.innerSpacing - 3) {
                            // Level 1: Target Monitor Info
                            HStack(spacing: 6) {
                                Image(systemName: windowTracker.activeScreenCategory == .builtIn ? "laptopcomputer" : "desktopcomputer")
                                    .font(.system(size: p.fontBody))
                                    .foregroundColor(windowTracker.activeScreenCategory == .builtIn ? .secondary : .blue)
                                let displayName = DisplayHistoryStore.shared.displayName(for: windowTracker.activeMonitorName, fallback: windowTracker.activeMonitorName)
                                Text("\(displayName) (\(windowTracker.activeMonitorModel))")
                                    .font(.system(size: p.fontBody, weight: .bold))
                                    .foregroundColor(.primary)
                                Spacer()
                                Text(windowTracker.activeScreenCategory.rawValue)
                                    .font(.system(size: p.fontBadge, weight: .medium))
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 2)
                                    .background(Color.secondary.opacity(0.15))
                                    .cornerRadius(4)
                            }

                            // Level 2: Active Application (Indented with Native App Icon)
                            HStack(spacing: 6) {
                                Text("↳")
                                    .font(.system(size: p.fontBody))
                                    .foregroundColor(.secondary)
                                
                                if let icon = AppCatalog.icon(for: windowTracker.activeAppBundleID) {
                                    Image(nsImage: icon)
                                        .resizable()
                                        .frame(width: p.fontBody + 2, height: p.fontBody + 2)
                                } else {
                                    Image(systemName: "app.fill")
                                        .font(.system(size: p.fontBody))
                                        .foregroundColor(.blue)
                                }

                                Text("\(windowTracker.activeAppName)")
                                    .font(.system(size: p.fontBody + 1, weight: .bold))
                                    .foregroundColor(.primary)
                            }
                            .padding(.leading, 12)

                            // Level 3: Active Tab / Sub-Window & Live Zoom Rate (Indented Twice)
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 6) {
                                    Text("↳")
                                        .font(.system(size: p.fontBody))
                                        .foregroundColor(.secondary)
                                    Image(systemName: windowTracker.isDomainExcluded ? "slash.circle.fill" : "doc.text.fill")
                                        .font(.system(size: p.fontCaption))
                                        .foregroundColor(windowTracker.isDomainExcluded ? .red : .secondary)
                                    Text(windowTracker.activeTabTitle)
                                        .font(.system(size: p.fontBody))
                                        .lineLimit(1)
                                        .foregroundColor(.primary)
                                    if let domain = windowTracker.activeTabDomain {
                                        Text("(\(domain))")
                                            .font(.system(size: p.fontBadge))
                                            .foregroundColor(.secondary)
                                    }
                                }

                                HStack(spacing: 6) {
                                    Text("   ")
                                    Text(windowTracker.activeZoomLevelString)
                                        .font(.system(size: p.fontBadge + 0.5, weight: .semibold))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(windowTracker.isDomainExcluded ? Color.red.opacity(0.15) : Color.blue.opacity(0.15))
                                        .foregroundColor(windowTracker.isDomainExcluded ? .red : .blue)
                                        .cornerRadius(4)
                                }
                            }
                            .padding(.leading, 24)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    Divider()

                    // Embedded Quick Zoom Controls (Applies to Focused App/Tab Only)
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Zoom Control (Applies to Focused App/Tab Only)")
                            .font(.system(size: p.fontCaption - 0.5, weight: .medium))
                            .foregroundColor(.secondary)

                        HStack(spacing: 6) {
                            Button(action: {
                                if let app = NSWorkspace.shared.menuBarOwningApplication {
                                    ZoomEngine.shared.execute(action: .reset100, for: app.processIdentifier, appName: app.localizedName ?? "")
                                }
                            }) {
                                Label("Reset 100%", systemImage: "arrow.counterclockwise")
                                    .font(.system(size: p.fontBody - 1))
                                    .frame(height: p.buttonHeight)
                            }
                            .buttonStyle(.bordered)

                            Spacer()

                            HStack(spacing: 4) {
                                Button(action: {
                                    if let app = NSWorkspace.shared.menuBarOwningApplication {
                                        ZoomEngine.shared.execute(action: .zoomOut(steps: 1), for: app.processIdentifier, appName: app.localizedName ?? "")
                                    }
                                }) {
                                    Image(systemName: "minus")
                                        .font(.system(size: p.fontBody - 1, weight: .bold))
                                        .frame(width: p.buttonHeight - 4, height: p.buttonHeight)
                                }
                                .buttonStyle(.bordered)
                                .help("Zoom Out (Cmd + '-')")

                                Button(action: {
                                    if let app = NSWorkspace.shared.menuBarOwningApplication {
                                        ZoomEngine.shared.execute(action: .zoomIn(steps: 1), for: app.processIdentifier, appName: app.localizedName ?? "")
                                    }
                                }) {
                                    Image(systemName: "plus")
                                        .font(.system(size: p.fontBody - 1, weight: .bold))
                                        .frame(width: p.buttonHeight - 4, height: p.buttonHeight)
                                }
                                .buttonStyle(.bordered)
                                .help("Zoom In (Cmd + '+')")
                            }
                        }
                    }
                }
                .padding(p.innerSpacing)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.secondary.opacity(0.12))
                .cornerRadius(8)
            }
            .popover(isPresented: $showingAppInspector) {
                FocusedAppInspectorView(
                    appName: windowTracker.activeAppName,
                    bundleID: windowTracker.activeAppBundleID,
                    screenName: windowTracker.activeScreenName,
                    screenCategory: windowTracker.activeScreenCategory,
                    onCreateRule: { targetBundleID in
                        onOpenSettingsWithPreset?(targetBundleID)
                    },
                    onCreateAutoMinimizeRule: { targetBundleID in
                        onOpenAutoMinimizePresetApp?(targetBundleID)
                    }
                )
            }

            Divider()

            // Available Displays Section
            VStack(alignment: .leading, spacing: p.innerSpacing - 3) {
                Text("AVAILABLE DISPLAYS (\(NSScreen.screens.count))")
                    .font(.system(size: p.fontSectionHeader, weight: .semibold))
                    .foregroundColor(.secondary)

                ForEach(NSScreen.screens, id: \.self) { screen in
                    let details = DisplayInfoProvider.details(for: screen)
                    let hwID = DisplayClassifier.permanentHardwareID(for: screen)
                    let displayName = historyStore.displayName(for: hwID, fallback: screen.localizedName)
                    Button(action: {
                        inspectingMonitor = details
                    }) {
                        HStack {
                            Circle()
                                .fill(details.isBuiltIn ? Color.secondary : Color.blue)
                                .frame(width: 8, height: 8)
                            Text(displayName)
                                .font(.system(size: p.fontBody))
                                .lineLimit(1)
                                .foregroundColor(.primary)
                            Spacer()
                            Text(details.category.rawValue)
                                .font(.system(size: p.fontBadge, weight: .medium))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.secondary.opacity(0.15))
                                .cornerRadius(4)
                            Image(systemName: "chevron.right")
                                .font(.system(size: p.fontBadge))
                                .foregroundColor(.secondary)
                        }
                        .padding(4)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .popover(item: $inspectingMonitor) { details in
                MonitorInspectorView(
                    details: details,
                    onCreateAutoMinimizeRuleForMonitor: { hardwareID in
                        onOpenAutoMinimizePresetMonitor?(hardwareID)
                    }
                )
            }

            Divider()

            // Global Actions Footer
            VStack(spacing: 6) {
                Button(action: {
                    NSApp.keyWindow?.orderOut(nil)
                    onOpenSettings()
                }) {
                    HStack {
                        Spacer()
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: p.fontBody))
                        Text("Settings")
                            .font(.system(size: p.fontBody, weight: .bold))
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
                            .font(.system(size: p.fontBody))
                        Text("Quit macDisplayMagic")
                            .font(.system(size: p.fontBody, weight: .bold))
                        Spacer()
                    }
                    .foregroundColor(.red)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(.horizontal, p.outerPaddingHorizontal)
        .padding(.vertical, p.outerPaddingVertical)
        .frame(width: p.containerWidth)
        .onAppear {
            accessibilityManager.refreshStatus()
        }
    }
}
