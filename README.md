# macDisplayMagic 🖥️✨

**macDisplayMagic** is a lightweight, display-aware macOS utility that automatically manages application zoom levels when windows move between MacBook Retina displays and high-density external monitors (4K, 5K, 8K, and UltraWide displays).

---

## 🌟 Key Features

- 🎯 **Automatic Window Transition Detection**: Seamlessly detects when an application window moves across displays and applies pre-configured zoom rules (`Cmd + '+'`, `Cmd + '-'`, or `Cmd + 0`).
- ⚡ **Instant 0ms Menu Bar Interface**: In-memory RAM caching eliminates kernel scanning latency, ensuring instant menu bar response.
- 🔬 **Full-Tree IOKit Hardware Inspector**: Reads monitor EDID attributes, serial numbers, manufacturer details, refresh rates (60 Hz, 120 Hz ProMotion), rotation orientation, and maps internal chassis codes to commercial retail model variants (e.g., `LG HDR 4K (32UP83A / 32UN880 / 32UN88)`).
- 🏷️ **Hardware & Serial Specific Zoom Rules**: Target rules to broad display resolution categories (e.g. `4K UHD`, `Built-in Retina`) or restrict rules to specific physical monitor models and serial numbers.
- 🔍 **Interactive Focus & Hardware Popovers**: Click any connected monitor card to inspect detailed hardware specifications or click the active window card to create application-specific rules with one click.
- ⚙️ **General Application Preferences**:
  - **Show Menubar Icon at Startup**: Toggle menu bar icon visibility.
  - **Start App when system starts**: Native macOS Launch at Login integration (`SMAppService`).
  - **When Closing Main Window**: Choose whether closing the settings window keeps the app running in the background or quits the application.
- 🎨 **Apple Human Interface Guidelines**: Sleek macOS design system with unified color coding (`Color.secondary` gray for built-in displays, `Color.blue` for external displays).

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

2. **Build and Create Application Bundle**:
   ```bash
   bash build_app.sh
   ```

3. **Launch the Application**:
   ```bash
   open dist/macDisplayMagic.app
   ```

---

## ⚙️ How It Works

### Rule Evaluation Decision Tree

When an application window transitions to another display, **macDisplayMagic** evaluates rules according to a strict priority hierarchy:

1. **App + Specific Monitor Serial Number** *(Highest Priority)*
2. **App + Specific Monitor Model Name**
3. **App + Display Resolution Category**
4. **Global + Specific Monitor Serial Number**
5. **Global + Specific Monitor Model Name**
6. **Global + Display Resolution Category** *(Fallback)*

### Accessibility Permission

**macDisplayMagic** requires standard macOS Accessibility permissions (`System Settings > Privacy & Security > Accessibility`) to observe active window positions and send macOS zoom keyboard shortcuts (`Cmd + '+'`, `Cmd + '-'`, `Cmd + 0`).

---

## 🛠️ Architecture

- **Core Frameworks**: Swift, SwiftUI, AppKit, CoreGraphics, IOKit, ServiceManagement
- **Single Instance Enforcement**: Enforces single-instance execution via bundle identifier and process name matching.
- **Cache Management**: Automatically invalidates RAM hardware cache when external displays are connected, disconnected, or reconfigured.

---

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.

---

**Author**: coolnick ([coolnickldd@gmail.com](mailto:coolnickldd@gmail.com))
