import SwiftUI

public struct RulesConfigView: View {
    @ObservedObject var rulesStore = RulesStore.shared
    @ObservedObject var appCatalog = AppCatalog.shared
    @ObservedObject var appSettings = AppSettings.shared

    @State private var showingAddSheet = false
    @State private var editingRuleID: UUID? = nil

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

    public init(presetBundleID: String? = nil) {
        if let preset = presetBundleID, !preset.isEmpty {
            _selectedAppSelection = State(initialValue: preset)
            _newRuleName = State(initialValue: "\(AppCatalog.displayName(for: preset)) 4K UHD Rule")
            _showingAddSheet = State(initialValue: true)
        }
    }

    public var body: some View {
        TabView {
            zoomRulesTab
                .tabItem {
                    Label("Zoom Rules", systemImage: "display.2")
                }

            generalSettingsTab
                .tabItem {
                    Label("General Settings", systemImage: "gearshape")
                }
        }
        .frame(width: 680, height: 480)
        .sheet(isPresented: $showingAddSheet) {
            addRuleSheet
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

                        // Setting 3: When Closing Main Window
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.orange.opacity(0.15))
                                    .frame(width: 32, height: 32)
                                Image(systemName: "xmark.circle")
                                    .foregroundColor(.orange)
                                    .font(.system(size: 14, weight: .semibold))
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("When Closing Main Window")
                                    .font(.body)
                                    .bold()
                                Text("Choose whether closing this settings window keeps the app running in background.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Picker("", selection: $appSettings.whenClosingMainWindow) {
                                ForEach(ClosingWindowAction.allCases) { action in
                                    Text(action.rawValue).tag(action)
                                }
                            }
                            .labelsHidden()
                            .frame(width: 190)
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
}
