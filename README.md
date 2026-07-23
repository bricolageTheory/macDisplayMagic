# macDisplayMagic 🖥️✨

**Display-Aware Application Zoom Manager** • `v0.2.0`

**macDisplayMagic** is a lightweight, display-aware macOS utility that automatically manages application and web tab zoom levels when windows move between MacBook and external monitors and displays (4K, 5K, 8K, and UltraWide displays).

💡 *Vibe-coded using Gemini 3.5 Flash (High) for testing & experimentation.*

---

## 🌟 Key Features

- 🎯 **Automatic Window & Display Transition Detection**: Seamlessly detects when an application window moves across displays and applies pre-configured zoom rules (`Cmd + '+'`, `Cmd + '-'`, or `Cmd + 0`).
- 🎨 **Dark Liquid Glass UI macOS App Icon**: Premium 3D liquid glass squircle icon with glowing cyan monitor and MacBook silhouettes, registered system-wide with macOS Launch Services.
- 🎛️ **11-Step Menu Size Zoom Engine (75% to 210%)**: Scale the menu bar popover interface across 11 discrete scale levels (`75%`, `85%`, `95%`, `100%`, `112%`, `125%`, `138%`, `150%`, `165%`, `185%`, `210%`) with compact ADA/WCAG-compliant controls (`[ ➖ ] [ ➕ ]`) and zero text truncation.
- 🌐 **Continuous Tab Zooming (`keepZooming`)**: Intercepts tab switches inside multi-tab web browsers (Google Chrome, Safari, Firefox, Arc, Brave) and applies display zoom to newly focused tabs.
- 🚫 **Domain Zoom Exclusions (`noZoomingDomain`)**: Define exclusion lists for media streaming or specific web domains (e.g. `netflix.com`, `youtube.com`, `disneyplus.com`) to bypass auto-zooming.
- ⚡ **Non-Blocking Async Domain Extraction**: High-performance targeted Accessibility queries (`kAXDocumentAttribute` / `kAXURLAttribute`) executed on a background queue, guaranteeing 0ms main thread UI latency.
- 🛰️ **Location Provenance & Connection Logs**: Logs physical display connection events tagged with location metadata and visual provenance icons (GPS, Network IP, System Timezone).
- 🔬 **Full-Tree IOKit Hardware Inspector**: Reads monitor EDID attributes, serial numbers, manufacturer details, refresh rates, and maps chassis codes to retail model names.
- 🏷️ **Hardware & Serial Specific Zoom Rules**: Target rules to broad resolution categories (e.g. `4K UHD`, `Built-in Retina`) or restrict rules to specific physical monitor models and serial numbers.
- 💻 **AutoMinimize Rules**: Automatically minimize open windows of designated applications when connecting to specific external monitors — fully editable via double-click.
- 🪟 **Resizable Settings Window**: The settings panel is fully resizable with macOS native drag handles; all four navigation tabs remain permanently visible at any window size.

---

## ⚙️ How It Works

### Rule Evaluation Decision Tree

When an application window or tab transitions to another display, **macDisplayMagic** evaluates zoom rules according to a strict priority hierarchy:

1. **App + Specific Monitor Serial Number** *(Highest Priority)*
2. **App + Specific Monitor Model Name**
3. **App + Display Resolution Category**
4. **Global + Specific Monitor Serial Number**
5. **Global + Specific Monitor Model Name**
6. **Global + Display Resolution Category** *(Fallback)*

---

## 🚀 Installation & Building from Source

### Prerequisites
- macOS 13.0 (Ventura) or later
- Swift 5.9+ / Xcode Command Line Tools

### Build Instructions

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/nicklee76/macDisplayMagic.git
   cd macDisplayMagic
   ```

2. **Build and Install Application Bundle**:
   ```bash
   bash build_app.sh --install
   ```
   *(Bundles `AppIcon.icns`, compiles the Swift sources, installs `macDisplayMagic.app` to `/Applications`, and registers with macOS Launch Services.)*

3. **Launch the Application**:
   ```bash
   open /Applications/macDisplayMagic.app
   ```

---

## 🔒 Privacy & Permissions

- **Accessibility Permission**: Required (`System Settings > Privacy & Security > Accessibility`) to observe active window positions and send macOS zoom keyboard shortcuts (`Cmd + '+'`, `Cmd + '-'`, `Cmd + 0`).
- **Location Permission (Optional)**: Used solely to tag physical connection logs (e.g. Office, Home). Your location data is stored strictly on your Mac in local `UserDefaults` and is **NEVER** transmitted or uploaded anywhere.

---

## 🛠️ Architecture & Technologies

- **Language & Frameworks**: Swift, SwiftUI, AppKit, CoreGraphics, CoreLocation, IOKit, ServiceManagement
- **Storage Isolation**: Local `UserDefaults` storage (`~/Library/Preferences/com.nicklee.macDisplayMagic.plist`) ensures personal connection logs and custom rules are never pushed to Git.

---

## 📋 Changelog

### v0.2.0 — 2026-07-23
- **Custom permanent tab navigation**: Replaced the native `TabView` (which collapses to `>>` overflow) with a fully custom pinned tab bar. All four tabs are always visible at any window width.
- **Resizable settings window**: Settings panel now supports native macOS window resizing. Opens at 860×580, minimum content area 720×480.
- **AutoMinimize double-click editing**: AutoMinimize rules can now be opened for editing by double-clicking the row or clicking the pencil button. Sheet title and Save button toggle between Add/Edit mode.
- **Tab bar size fix**: Corrected `NSWindow.contentMinSize` vs `minSize` mismatch that caused the tab bar to visually compress when the window approached its minimum height.
- **Uniform menu popover padding**: Fixed asymmetric bottom padding in the menu bar popover by switching to a single `.padding()` call covering all four sides equally.
- **Removed "Refresh Location & Diagnostics" button**: Feature removed; `LocationService` is still used internally for automatic monitor connection geo-tagging.
- **Project cleanup**: Removed unused backup files (`AppIcon.icns.bak`, `AppIcon.icns.old`, `main_menu.png`), dead code (`stopListening`, unused `AccessibilityManager` methods, `previousScreenCount`), and applied industry-standard doc-comments throughout core services.

### v0.1.0
- Initial public release with zoom rule engine, display monitoring, AutoMinimize, and location-tagged connection history.

---

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.

---

**Author**: Nick Lee ([coolnickldd@gmail.com](mailto:coolnickldd@gmail.com))
