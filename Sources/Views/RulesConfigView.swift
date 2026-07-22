import SwiftUI

public struct RulesConfigView: View {
    @ObservedObject var rulesStore = RulesStore.shared
    @ObservedObject var appCatalog = AppCatalog.shared
    @ObservedObject var appSettings = AppSettings.shared

    @ObservedObject var historyStore = DisplayHistoryStore.shared

    @State private var showingAddSheet = false
    @State private var editingRuleID: UUID? = nil

    @State private var showingAddAutoMinimizeSheet = false
    @State private var newAutoMinimizeName: String = ""
    @State private var autoMinimizeSelectedAppIDs: Set<String> = []
    @State private var newAutoMinimizeTitlePattern: String = ""

    // Form fields
    @State private var newRuleName: String = ""
    @State private var selectedAppSelection: String = "" // "" for All Apps, or bundleID
    @State private var customBundleID: String = ""
    @State private var isCustomApp: Bool = false

    @State private var selectedMonitorSelection: String = "" // "" for Any Monitor, "CUSTOM", or "MODEL||SERIAL"
    @State private var customMonitorModel: String = ""
    @State private var customMonitorSerial: String = ""
    @State private var isCustomMonitor: Bool = false

    @State private var selectedCategory: DisplayCategory = .uhd4K
    @State private var actionType: Int = 1 // 0: Reset 100%, 1: Zoom In, 2: Zoom Out
    @State private var zoomSteps: Int = 2
    @State private var newDomainInput: String = ""

    @State private var autoMinimizeDisplayTargetMode: Int = 0 // 0: Any, 1: Unknown, 2: Known, 3: Specific
    @State private var autoMinimizeSelectedHardwareID: String = ""

    @State private var inspectingHistoryRecord: DisplayHistoryRecord? = nil

    public init(
        presetBundleID: String? = nil,
        presetAutoMinimizeAppID: String? = nil,
        presetAutoMinimizeHardwareID: String? = nil
    ) {
        if let preset = presetBundleID, !preset.isEmpty {
            _selectedAppSelection = State(initialValue: preset)
            _newRuleName = State(initialValue: "\(AppCatalog.displayName(for: preset)) 4K UHD Rule")
            _showingAddSheet = State(initialValue: true)
        } else if let presetApp = presetAutoMinimizeAppID, !presetApp.isEmpty {
            _autoMinimizeSelectedAppIDs = State(initialValue: [presetApp])
            _newAutoMinimizeName = State(initialValue: "Minimize \(AppCatalog.displayName(for: presetApp))")
            _showingAddAutoMinimizeSheet = State(initialValue: true)
        } else if let presetMonitor = presetAutoMinimizeHardwareID, !presetMonitor.isEmpty {
            let nickname = DisplayHistoryStore.shared.displayName(for: presetMonitor, fallback: presetMonitor)
            _newAutoMinimizeName = State(initialValue: "Minimize on \(nickname)")
            _autoMinimizeDisplayTargetMode = State(initialValue: 3)
            _autoMinimizeSelectedHardwareID = State(initialValue: presetMonitor)
            _showingAddAutoMinimizeSheet = State(initialValue: true)
        }
    }

    public var body: some View {
        TabView {
            zoomRulesTab
                .tabItem {
                    Label("Zoom Rules", systemImage: "rectangle.3.group")
                }

            generalSettingsTab
                .tabItem {
                    Label("General Settings", systemImage: "gearshape")
                }

            monitorHistoryTab
                .tabItem {
                    Label("External Display Connection History", systemImage: "clock.arrow.circlepath")
                }

            autoMinimizeTab
                .tabItem {
                    Label("AutoMinimize Rules", systemImage: "arrow.down.right.and.arrow.up.left")
                }
        }
        .frame(width: 720, height: 520)
        .sheet(isPresented: $showingAddSheet) {
            addRuleSheet
        }
        .sheet(isPresented: $showingAddAutoMinimizeSheet) {
            addAutoMinimizeSheet
        }
        .onAppear {
            refreshApps()
        }
    }

    private var zoomRulesTab: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("macDisplayMagic Configuration")
                        .font(.title2)
                        .bold()
                    Text("Double-click any rule to edit. Manage display zoom preferences below.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button(action: {
                    resetForm()
                    refreshApps()
                    showingAddSheet = true
                }) {
                    Label("Add Rule", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))

            Divider()

            // Rules List
            List {
                Section(header: Text("Active Display & Zoom Rules (Double-Click to Edit)").font(.headline)) {
                    ForEach($rulesStore.rules) { $rule in
                        HStack(spacing: 16) {
                            Toggle("", isOn: $rule.isEnabled)
                                .labelsHidden()

                            VStack(alignment: .leading, spacing: 4) {
                                Text(rule.name)
                                    .font(.headline)
                                HStack(spacing: 6) {
                                    if let appID = rule.appBundleID, !appID.isEmpty {
                                        let appTitle = AppCatalog.displayName(for: appID)
                                        let appIcon = AppCatalog.icon(for: appID)
                                        HStack(spacing: 4) {
                                            if let icon = appIcon {
                                                Image(nsImage: icon)
                                                    .resizable()
                                                    .frame(width: 10, height: 10)
                                            } else {
                                                Image(systemName: "app.fill")
                                            }
                                            Text("\(appTitle) (\(appID))")
                                        }
                                        .font(.caption)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.blue.opacity(0.15))
                                        .cornerRadius(4)
                                    } else {
                                        Label("All Applications", systemImage: "globe")
                                            .font(.caption)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.purple.opacity(0.15))
                                            .cornerRadius(4)
                                    }

                                    if let serial = rule.targetMonitorSerial, !serial.isEmpty {
                                        Label("S/N: \(serial)", systemImage: "barcode")
                                            .font(.caption)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.green.opacity(0.15))
                                            .cornerRadius(4)
                                    } else if let model = rule.targetMonitorModel, !model.isEmpty {
                                        Label("Model: \(model)", systemImage: "desktopcomputer")
                                            .font(.caption)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.mint.opacity(0.15))
                                            .cornerRadius(4)
                                    } else if let category = rule.displayCategory {
                                        Label(category.rawValue, systemImage: "desktopcomputer")
                                            .font(.caption)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.orange.opacity(0.15))
                                            .cornerRadius(4)
                                    }
                                }
                            }

                            Spacer()

                            Text(rule.action.description)
                                .font(.callout)
                                .foregroundColor(.secondary)

                            HStack(spacing: 12) {
                                Button(action: {
                                    editRule(rule)
                                }) {
                                    Image(systemName: "pencil")
                                        .foregroundColor(.blue)
                                }
                                .buttonStyle(.plain)
                                .help("Edit Rule")

                                Button(action: {
                                    deleteRule(rule)
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(.plain)
                                .help("Delete Rule")
                            }
                        }
                        .padding(.vertical, 6)
                        .contentShape(Rectangle())
                        .onTapGesture(count: 2) {
                            editRule(rule)
                        }
                    }
                }
            }
            .listStyle(.inset)
        }
    }

    private var generalSettingsTab: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("General Application Settings")
                        .font(.title2)
                        .bold()
                    Text("Configure startup preferences and main window behavior.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))

            Divider()

            ScrollView {
                VStack(spacing: 16) {
                    // Grouped Settings Card
                    VStack(spacing: 0) {
                        // Setting 1: Show Menubar Icon at Startup
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.blue.opacity(0.15))
                                    .frame(width: 32, height: 32)
                                Image(systemName: "display")
                                    .foregroundColor(.blue)
                                    .font(.system(size: 14, weight: .semibold))
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Show Menubar Icon at Startup")
                                    .font(.body)
                                    .bold()
                                Text("Display the macDisplayMagic icon in the macOS status menu bar on launch.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Toggle("", isOn: $appSettings.showMenubarIconAtStartup)
                                .toggleStyle(.switch)
                                .labelsHidden()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)

                        Divider()
                            .padding(.leading, 56)

                        // Setting 2: Start App when system starts
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.green.opacity(0.15))
                                    .frame(width: 32, height: 32)
                                Image(systemName: "power")
                                    .foregroundColor(.green)
                                    .font(.system(size: 14, weight: .semibold))
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Start App when system starts")
                                    .font(.body)
                                    .bold()
                                Text("Automatically launch macDisplayMagic when logging into macOS.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Toggle("", isOn: $appSettings.startAtLogin)
                                .toggleStyle(.switch)
                                .labelsHidden()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)

                        Divider()
                            .padding(.leading, 56)



                        // Setting 4: Continuous Tab Zooming (keepZooming)
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.purple.opacity(0.15))
                                    .frame(width: 32, height: 32)
                                Image(systemName: "square.stack.3d.up.fill")
                                    .foregroundColor(.purple)
                                    .font(.system(size: 14, weight: .semibold))
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Enable Continuous Tab Zooming (keepZooming)")
                                    .font(.body)
                                    .bold()
                                Text("Automatically apply target display zoom when switching tabs inside multi-tab applications.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Toggle("", isOn: $appSettings.enableKeepZooming)
                                .toggleStyle(.switch)
                                .labelsHidden()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)

                        Divider()
                            .padding(.leading, 56)

                        // Setting 5: Domain Zoom Exclusions (noZoomingDomain)
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(Color.red.opacity(0.15))
                                        .frame(width: 32, height: 32)
                                    Image(systemName: "slash.circle.fill")
                                        .foregroundColor(.red)
                                        .font(.system(size: 14, weight: .semibold))
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Domain Zoom Exclusions (noZoomingDomain)")
                                        .font(.body)
                                        .bold()
                                    Text("Skip auto-zooming for specific web domains (e.g. netflix.com, youtube.com).")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                Toggle("", isOn: $appSettings.enableNoZoomingDomain)
                                    .toggleStyle(.switch)
                                    .labelsHidden()
                            }

                            if appSettings.enableNoZoomingDomain {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        TextField("Add excluded domain (e.g. disneyplus.com)...", text: $newDomainInput)
                                            .textFieldStyle(.roundedBorder)
                                        Button("Add Domain") {
                                            appSettings.addNoZoomDomain(newDomainInput)
                                            newDomainInput = ""
                                        }
                                        .buttonStyle(.borderedProminent)
                                        .disabled(newDomainInput.trimmingCharacters(in: .whitespaces).isEmpty)
                                    }

                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 6) {
                                            ForEach(appSettings.noZoomDomains, id: \.self) { domain in
                                                HStack(spacing: 4) {
                                                    Text(domain)
                                                        .font(.caption)
                                                    Button(action: {
                                                        appSettings.removeNoZoomDomain(domain)
                                                    }) {
                                                        Image(systemName: "xmark.circle.fill")
                                                            .font(.caption)
                                                    }
                                                    .buttonStyle(.plain)
                                                }
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(Color.red.opacity(0.15))
                                                .cornerRadius(6)
                                            }
                                        }
                                    }
                                }
                                .padding(.leading, 44)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                    )
                }
                .padding(20)
            }

            Spacer()
        }
    }

    private var addRuleSheet: some View {
        VStack(spacing: 16) {
            Text(editingRuleID == nil ? "Create New Zoom Rule" : "Edit Zoom Rule")
                .font(.title3)
                .bold()

            Form {
                Picker("Target Application:", selection: $selectedAppSelection) {
                    Text("🌐 All Applications (Global)").tag("")

                    if !appCatalog.runningApps.isEmpty {
                        Divider()
                        Text("-- Currently Running Apps --").disabled(true)
                        ForEach(appCatalog.runningApps) { app in
                            Label {
                                Text("\(app.name) (\(app.bundleID))")
                            } icon: {
                                if let icon = app.icon {
                                    Image(nsImage: icon)
                                } else {
                                    Image(systemName: "app.fill")
                                }
                            }
                            .tag(app.bundleID)
                        }
                    }

                    Divider()
                    Text("-- Popular Application Presets --").disabled(true)
                    ForEach(AppCatalog.knownPresets) { preset in
                        Label {
                            Text("\(preset.name) (\(preset.bundleID))")
                        } icon: {
                            if let icon = preset.icon {
                                Image(nsImage: icon)
                            } else {
                                Image(systemName: "star.fill")
                            }
                        }
                        .tag(preset.bundleID)
                    }

                    Divider()
                    Text("✏️ Enter Custom Bundle ID...").tag("CUSTOM")
                }
                .onChange(of: selectedAppSelection) { newValue in
                    if newValue == "CUSTOM" {
                        isCustomApp = true
                    } else {
                        isCustomApp = false
                        if editingRuleID == nil {
                            autoSuggestRuleName(bundleID: newValue)
                        }
                    }
                }

                if isCustomApp {
                    TextField("Custom App Bundle ID (e.g. org.mozilla.firefox):", text: $customBundleID)
                        .onChange(of: customBundleID) { newValue in
                            if editingRuleID == nil {
                                autoSuggestRuleName(bundleID: newValue)
                            }
                        }
                }

                // Target Display / Monitor Selection
                Picker("Target Display / Monitor:", selection: $selectedMonitorSelection) {
                    Text("🌐 Any Monitor in Display Category (Default)").tag("")

                    let screens = NSScreen.screens
                    if !screens.isEmpty {
                        Divider()
                        Text("-- Connected Monitors --").disabled(true)
                        ForEach(screens, id: \.self) { screen in
                            let details = DisplayInfoProvider.details(for: screen)
                            let tagVal = "\(details.modelName)||\(details.serialNumber)"
                            Label {
                                Text("\(details.name) (Model: \(details.modelName), S/N: \(details.serialNumber))")
                            } icon: {
                                Image(systemName: details.isBuiltIn ? "laptopcomputer" : "desktopcomputer")
                            }
                            .tag(tagVal)
                        }
                    }

                    Divider()
                    Text("✏️ Specific Model or Serial Number...").tag("CUSTOM")
                }
                .onChange(of: selectedMonitorSelection) { newValue in
                    if newValue == "CUSTOM" {
                        isCustomMonitor = true
                    } else {
                        isCustomMonitor = false
                        if !newValue.isEmpty {
                            let parts = newValue.components(separatedBy: "||")
                            if parts.count == 2 {
                                customMonitorModel = parts[0]
                                customMonitorSerial = parts[1] == "N/A" ? "" : parts[1]
                            }
                        } else {
                            customMonitorModel = ""
                            customMonitorSerial = ""
                        }
                    }
                }

                if isCustomMonitor {
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("Target Monitor Model (Optional, e.g. 32UN88):", text: $customMonitorModel)
                        TextField("Target Monitor Serial Number (Optional, e.g. 208NTGY9G575):", text: $customMonitorSerial)
                    }
                }

                TextField("Rule Name:", text: $newRuleName)

                Picker("Display Category:", selection: $selectedCategory) {
                    ForEach(DisplayCategory.allCases) { category in
                        Text(category.rawValue).tag(category)
                    }
                }
                .onChange(of: selectedCategory) { _ in
                    if editingRuleID == nil {
                        let targetID = isCustomApp ? customBundleID : selectedAppSelection
                        autoSuggestRuleName(bundleID: targetID)
                    }
                }

                Picker("Action:", selection: $actionType) {
                    Text("Reset to 100% (Cmd + 0)").tag(0)
                    Text("Zoom In (Cmd + '+')").tag(1)
                    Text("Zoom Out (Cmd + '-')").tag(2)
                }

                if actionType == 1 || actionType == 2 {
                    Stepper("Zoom Steps: +\(zoomSteps)", value: $zoomSteps, in: 1...5)
                }
            }

            HStack {
                Button("Cancel") {
                    resetForm()
                    showingAddSheet = false
                }

                Spacer()

                Button(editingRuleID == nil ? "Save Rule" : "Update Rule") {
                    saveNewRule()
                    showingAddSheet = false
                }
                .buttonStyle(.borderedProminent)
                .disabled(newRuleName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding()
        .frame(width: 520, height: 440)
    }

    private func refreshApps() {
        appCatalog.refreshRunningApps()
    }

    private func editRule(_ rule: ZoomRule) {
        refreshApps()
        editingRuleID = rule.id
        newRuleName = rule.name
        selectedCategory = rule.displayCategory ?? .uhd4K

        customMonitorModel = rule.targetMonitorModel ?? ""
        customMonitorSerial = rule.targetMonitorSerial ?? ""

        if rule.targetMonitorModel != nil || rule.targetMonitorSerial != nil {
            let matchedScreen = NSScreen.screens.first { screen in
                let details = DisplayInfoProvider.details(for: screen)
                return details.serialNumber == rule.targetMonitorSerial || details.modelName == rule.targetMonitorModel
            }
            if let screen = matchedScreen {
                let details = DisplayInfoProvider.details(for: screen)
                selectedMonitorSelection = "\(details.modelName)||\(details.serialNumber)"
                isCustomMonitor = false
            } else {
                selectedMonitorSelection = "CUSTOM"
                isCustomMonitor = true
            }
        } else {
            selectedMonitorSelection = ""
            isCustomMonitor = false
        }

        switch rule.action {
        case .reset100:
            actionType = 0
            zoomSteps = 1
        case .zoomIn(let steps):
            actionType = 1
            zoomSteps = steps
        case .zoomOut(let steps):
            actionType = 2
            zoomSteps = steps
        }

        if let appID = rule.appBundleID, !appID.isEmpty {
            let isRunning = appCatalog.runningApps.contains(where: { $0.bundleID == appID })
            let isPreset = AppCatalog.knownPresets.contains(where: { $0.bundleID == appID })
            if isRunning || isPreset {
                selectedAppSelection = appID
                isCustomApp = false
            } else {
                selectedAppSelection = "CUSTOM"
                customBundleID = appID
                isCustomApp = true
            }
        } else {
            selectedAppSelection = ""
            isCustomApp = false
        }

        showingAddSheet = true
    }

    private func resetForm() {
        editingRuleID = nil
        newRuleName = ""
        selectedAppSelection = ""
        customBundleID = ""
        isCustomApp = false
        selectedMonitorSelection = ""
        customMonitorModel = ""
        customMonitorSerial = ""
        isCustomMonitor = false
        actionType = 1
        zoomSteps = 2
    }

    private func autoSuggestRuleName(bundleID: String) {
        let appTitle: String
        if bundleID.isEmpty {
            appTitle = "Global"
        } else {
            appTitle = AppCatalog.displayName(for: bundleID)
        }

        let monitorDesc: String
        if !customMonitorModel.isEmpty {
            monitorDesc = customMonitorModel
        } else if !customMonitorSerial.isEmpty {
            monitorDesc = "S/N \(customMonitorSerial)"
        } else {
            monitorDesc = selectedCategory.rawValue
        }

        newRuleName = "\(appTitle) \(monitorDesc) Rule"
    }

    private func saveNewRule() {
        let action: ZoomAction
        if actionType == 0 {
            action = .reset100
        } else if actionType == 1 {
            action = .zoomIn(steps: zoomSteps)
        } else {
            action = .zoomOut(steps: zoomSteps)
        }

        let effectiveBundleID: String?
        if isCustomApp {
            let trimmed = customBundleID.trimmingCharacters(in: .whitespaces)
            effectiveBundleID = trimmed.isEmpty ? nil : trimmed
        } else {
            effectiveBundleID = selectedAppSelection.isEmpty ? nil : selectedAppSelection
        }

        let effectiveModel: String? = customMonitorModel.trimmingCharacters(in: .whitespaces).isEmpty ? nil : customMonitorModel.trimmingCharacters(in: .whitespaces)
        let effectiveSerial: String? = customMonitorSerial.trimmingCharacters(in: .whitespaces).isEmpty ? nil : customMonitorSerial.trimmingCharacters(in: .whitespaces)

        if let editID = editingRuleID, let index = rulesStore.rules.firstIndex(where: { $0.id == editID }) {
            rulesStore.rules[index].name = newRuleName
            rulesStore.rules[index].appBundleID = effectiveBundleID
            rulesStore.rules[index].displayCategory = selectedCategory
            rulesStore.rules[index].targetMonitorModel = effectiveModel
            rulesStore.rules[index].targetMonitorSerial = effectiveSerial
            rulesStore.rules[index].action = action
        } else {
            let rule = ZoomRule(
                name: newRuleName,
                appBundleID: effectiveBundleID,
                displayCategory: selectedCategory,
                targetMonitorModel: effectiveModel,
                targetMonitorSerial: effectiveSerial,
                action: action,
                isEnabled: true
            )
            rulesStore.rules.append(rule)
        }

        resetForm()
    }

    private func deleteRule(_ rule: ZoomRule) {
        rulesStore.rules.removeAll(where: { $0.id == rule.id })
    }

    // MARK: - External Display Connection History Tab
    
    private var monitorHistoryTab: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("External Display Connection History")
                        .font(.title2)
                        .bold()
                    Text("Click any monitor entry below to inspect full hardware specs or set a custom display nickname.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                HStack(spacing: 8) {
                    Button(action: {
                        LocationService.shared.fetchCurrentLocationName { resolved in
                            print("[macDisplayMagic] Diagnostic Refresh resolved location to: \(resolved)")
                        }
                    }) {
                        Label("Refresh Location & Diagnostics", systemImage: "location.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Clear History") {
                        historyStore.clearHistory()
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))

            Divider()

            // Privacy Guarantee Banner
            HStack(spacing: 10) {
                Image(systemName: "lock.shield.fill")
                    .font(.title3)
                    .foregroundColor(.green)
                VStack(alignment: .leading, spacing: 2) {
                    Text("100% On-Device Privacy Guarantee")
                        .font(.caption)
                        .bold()
                        .foregroundColor(.primary)
                    Text("Location services are used solely to tag physical connection logs when external displays are plugged in (e.g., Office, Home). Your location data is stored strictly on your Mac and is NEVER transmitted, uploaded, or shared with anyone.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(10)
            .background(Color.green.opacity(0.12))
            .cornerRadius(8)
            .padding(.horizontal)
            .padding(.top, 8)

            List {
                Section(header: Text("Connected & Historical Monitor Log (\(historyStore.historyRecords.count))").font(.headline)) {
                    if historyStore.historyRecords.isEmpty {
                        Text("No monitor connection history logged yet. Connect an external monitor to log time & physical location.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 12)
                    } else {
                        ForEach(historyStore.historyRecords) { record in
                            Button(action: {
                                inspectingHistoryRecord = record
                            }) {
                                HStack(spacing: 10) {
                                    Circle()
                                        .fill(record.category == .builtIn ? Color.secondary : Color.blue)
                                        .frame(width: 8, height: 8)

                                    Text(record.effectiveName)
                                        .font(.headline)
                                        .lineLimit(1)

                                    Spacer(minLength: 12)

                                    HStack(spacing: 6) {
                                        Image(systemName: record.locationSource.systemImage)
                                            .font(.caption2)
                                            .foregroundColor(record.locationSource == .gps ? .blue : (record.locationSource == .ip ? .purple : (record.locationSource == .timezone ? .orange : .red)))
                                        Text(record.locationName)
                                            .font(.caption)
                                            .bold()
                                            .lineLimit(1)
                                        Text("•")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                        Text(record.connectedAt.formatted(date: .abbreviated, time: .shortened))
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                        Image(systemName: "chevron.right")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    .layoutPriority(1)
                                }
                                .padding(.vertical, 6)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            Divider()

            // Location Source Legends Bar
            HStack(spacing: 12) {
                Text("LOCATION SOURCE LEGENDS:")
                    .font(.caption2)
                    .bold()
                    .foregroundColor(.secondary)

                HStack(spacing: 4) {
                    Image(systemName: LocationSource.gps.systemImage)
                        .font(.caption2)
                        .foregroundColor(.blue)
                    Text("CoreLocation (Wi-Fi/GPS)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 4) {
                    Image(systemName: LocationSource.ip.systemImage)
                        .font(.caption2)
                        .foregroundColor(.purple)
                    Text("Network IP")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 4) {
                    Image(systemName: LocationSource.timezone.systemImage)
                        .font(.caption2)
                        .foregroundColor(.orange)
                    Text("System Timezone")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor))
        }
        .sheet(item: $inspectingHistoryRecord) { record in
            DisplayHistoryDetailView(record: record)
        }
        .onAppear {
            LocationService.shared.fetchCurrentLocationName { _ in }
        }
    }

    // MARK: - AutoMinimize Tab
    
    private var autoMinimizeTab: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("AutoMinimize Rules")
                        .font(.title2)
                        .bold()
                    Text("Automatically minimize target applications or windows when an external monitor connects (Zero Notifications).")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button(action: {
                    newAutoMinimizeName = ""
                    autoMinimizeSelectedAppIDs.removeAll()
                    newAutoMinimizeTitlePattern = ""
                    showingAddAutoMinimizeSheet = true
                }) {
                    Label("Add AutoMinimize Rule", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))

            Divider()

            List {
                Section(header: Text("Active AutoMinimize Rules").font(.headline)) {
                    if appSettings.autoMinimizeRules.isEmpty {
                        Text("No AutoMinimize rules configured yet. Click 'Add AutoMinimize Rule' to minimize apps/windows silently on monitor connect.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 12)
                    } else {
                        ForEach($appSettings.autoMinimizeRules) { $rule in
                            HStack(spacing: 16) {
                                Toggle("", isOn: $rule.isEnabled)
                                    .labelsHidden()

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(rule.name)
                                        .font(.headline)
                                    HStack(spacing: 8) {
                                        ForEach(rule.targetBundleIDs, id: \.self) { bundleID in
                                            HStack(spacing: 4) {
                                                if let icon = AppCatalog.icon(for: bundleID) {
                                                    Image(nsImage: icon)
                                                        .resizable()
                                                        .frame(width: 12, height: 12)
                                                }
                                                Text(AppCatalog.displayName(for: bundleID))
                                                    .font(.caption)
                                            }
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.secondary.opacity(0.15))
                                            .cornerRadius(4)
                                        }

                                        if !rule.windowTitlePattern.isEmpty {
                                            Text("Window Title: '\(rule.windowTitlePattern)'")
                                                .font(.caption2)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color.purple.opacity(0.15))
                                                .foregroundColor(.purple)
                                                .cornerRadius(4)
                                        }
                                    }
                                }

                                Spacer()

                                Button(action: {
                                    appSettings.autoMinimizeRules.removeAll(where: { $0.id == rule.id })
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Add AutoMinimize Sheet Modal
    
    private var addAutoMinimizeSheet: some View {
        VStack(spacing: 16) {
            Text("Add AutoMinimize Rule")
                .font(.headline)

            VStack(alignment: .leading, spacing: 6) {
                Text("Rule Name:")
                    .font(.caption)
                    .bold()
                TextField("e.g. Minimize Music & Messaging", text: $newAutoMinimizeName)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Select Applications to Minimize:")
                    .font(.caption)
                    .bold()

                ScrollView {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(appCatalog.runningApps, id: \.bundleID) { app in
                            Toggle(isOn: Binding(
                                get: { autoMinimizeSelectedAppIDs.contains(app.bundleID) },
                                set: { selected in
                                    if selected {
                                        autoMinimizeSelectedAppIDs.insert(app.bundleID)
                                    } else {
                                        autoMinimizeSelectedAppIDs.remove(app.bundleID)
                                    }
                                }
                            )) {
                                HStack(spacing: 6) {
                                    if let icon = AppCatalog.icon(for: app.bundleID) {
                                        Image(nsImage: icon)
                                            .resizable()
                                            .frame(width: 14, height: 14)
                                    }
                                    Text(app.name)
                                        .font(.subheadline)
                                }
                            }
                            .toggleStyle(.checkbox)
                        }
                    }
                    .padding(8)
                }
                .frame(height: 140)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(6)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Optional Window Title Filter (Leave blank for all windows):")
                    .font(.caption)
                    .bold()
                TextField("e.g. Spotify or Chat...", text: $newAutoMinimizeTitlePattern)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Monitor Trigger Condition:")
                    .font(.caption)
                    .bold()
                Picker("", selection: $autoMinimizeDisplayTargetMode) {
                    Text("Any External Monitor").tag(0)
                    Text("Unknown / New External Monitors Only (Privacy Mode)").tag(1)
                    Text("Known External Monitors Only").tag(2)
                    Text("Specific External Monitor...").tag(3)
                }
                .labelsHidden()

                if autoMinimizeDisplayTargetMode == 3 {
                    Picker("Select Specific Monitor:", selection: $autoMinimizeSelectedHardwareID) {
                        if historyStore.historyRecords.isEmpty {
                            Text("No saved monitors in history yet").tag("")
                        } else {
                            ForEach(historyStore.historyRecords) { record in
                                Text("\(record.effectiveName) (\(record.locationName))").tag(record.hardwareID)
                            }
                        }
                    }
                    .font(.caption)
                }
            }

            HStack {
                Button("Cancel") {
                    showingAddAutoMinimizeSheet = false
                }

                Spacer()

                Button("Save Rule") {
                    let target: AutoMinimizeDisplayTarget
                    switch autoMinimizeDisplayTargetMode {
                    case 0: target = .anyExternal
                    case 1: target = .unknownOnly
                    case 2: target = .knownOnly
                    case 3: target = .specific(hardwareID: autoMinimizeSelectedHardwareID)
                    default: target = .anyExternal
                    }

                    let ruleName = newAutoMinimizeName.trimmingCharacters(in: .whitespaces).isEmpty ? "AutoMinimize Rule" : newAutoMinimizeName
                    let rule = AutoMinimizeRule(
                        name: ruleName,
                        targetBundleIDs: Array(autoMinimizeSelectedAppIDs),
                        windowTitlePattern: newAutoMinimizeTitlePattern.trimmingCharacters(in: .whitespaces),
                        displayTarget: target,
                        isEnabled: true
                    )
                    appSettings.autoMinimizeRules.append(rule)
                    showingAddAutoMinimizeSheet = false
                }
                .buttonStyle(.borderedProminent)
                .disabled(autoMinimizeSelectedAppIDs.isEmpty)
            }
        }
        .padding(20)
        .frame(width: 480, height: 490)
    }
}

public struct DisplayHistoryDetailView: View {
    public let record: DisplayHistoryRecord
    @ObservedObject var historyStore = DisplayHistoryStore.shared
    @State private var customNicknameInput: String = ""
    @Environment(\.dismiss) var dismiss

    public init(record: DisplayHistoryRecord) {
        self.record = record
        _customNicknameInput = State(initialValue: DisplayHistoryStore.shared.customNamesMap[record.hardwareID] ?? "")
    }

    public var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: record.category == .builtIn ? "laptopcomputer" : "desktopcomputer")
                    .font(.largeTitle)
                    .foregroundColor(record.category == .builtIn ? .green : .blue)

                VStack(alignment: .leading, spacing: 2) {
                    Text(record.effectiveName)
                        .font(.headline)
                        .bold()
                    Text("Connection Event Log • \(record.category.rawValue)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))

            Divider()

            // Hardware & Location Specs Table
            VStack(spacing: 8) {
                infoRow(title: "Display Model Name:", value: record.defaultName)
                infoRow(title: "Hardware Composite ID:", value: record.hardwareID)
                infoRow(title: "Native Resolution:", value: record.resolution)
                infoRow(title: "Display Category:", value: record.category.rawValue)
                infoRow(title: "Connection Timestamp:", value: record.connectedAt.formatted(date: .long, time: .standard))
                infoRow(title: "Physical Location Tag:", value: record.locationName)
                infoRow(title: "Resolution Provider:", value: "\(record.locationSource.emoji) \(record.locationSource.rawValue)")

                // Location Provenance Callout Box
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: record.locationSource.systemImage)
                            .font(.caption2)
                            .foregroundColor(record.locationSource == .gps ? .blue : (record.locationSource == .ip ? .purple : .orange))
                        Text("Location Provenance Details (\(record.locationSource.shortLabel)):")
                            .font(.caption2)
                            .bold()
                            .foregroundColor(.primary)
                    }
                    Text(record.locationSource.detailedDescription)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.secondary.opacity(0.08))
                .cornerRadius(6)
            }
            .padding(.horizontal)

            Divider()

            // Custom Display Nickname Editor with Submit Button & Character Counter
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Assign Custom Display Nickname:")
                        .font(.caption)
                        .bold()
                    Spacer()
                    Text("\(customNicknameInput.count)/30")
                        .font(.caption2)
                        .bold()
                        .foregroundColor(customNicknameInput.count >= 30 ? .orange : .secondary)
                }

                HStack(spacing: 8) {
                    TextField("e.g. Office Desk 4K...", text: $customNicknameInput)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: customNicknameInput) { newValue in
                            if newValue.count > 30 {
                                customNicknameInput = String(newValue.prefix(30))
                            }
                        }

                    Button("Save Custom Nickname") {
                        historyStore.setCustomName(customNicknameInput, for: record.hardwareID)
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(.horizontal)

            Spacer()

            HStack {
                Spacer()
                Button("Close") {
                    dismiss()
                }
                .buttonStyle(.bordered)
            }
            .padding()
        }
        .frame(width: 480, height: 480)
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
