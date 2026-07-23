#!/bin/bash
set -e

echo "==> Building macDisplayMagic executable..."
swift build -c release

APP_DIR="dist/macDisplayMagic.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "==> Creating Application Bundle ($APP_DIR)..."
rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

cp .build/release/macDisplayMagic "$MACOS_DIR/macDisplayMagic"

# Icon handling: prefer a hand-crafted AppIcon.icns from Resources/ (used as-is, no resampling).
# Falls back to converting AppIcon.png if no pre-built .icns is found.
if [ -f "Resources/AppIcon.icns" ]; then
    echo "==> Using pre-built Resources/AppIcon.icns directly (no PNG conversion)."
    cp "Resources/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"
    echo "==> AppIcon.icns bundled successfully."
elif [ -f "Resources/AppIcon.png" ] || [ -f "AppIcon.png" ]; then
    ICON_SRC="Resources/AppIcon.png"
    [ -f "AppIcon.png" ] && ICON_SRC="AppIcon.png"
    echo "==> Converting $ICON_SRC to macOS AppIcon.icns..."
    ICONSET_DIR="dist/AppIcon.iconset"
    rm -rf "$ICONSET_DIR"
    mkdir -p "$ICONSET_DIR"
    sips -s format png -z 16 16     "$ICON_SRC" --out "$ICONSET_DIR/icon_16x16.png" > /dev/null 2>&1
    sips -s format png -z 32 32     "$ICON_SRC" --out "$ICONSET_DIR/icon_16x16@2x.png" > /dev/null 2>&1
    sips -s format png -z 32 32     "$ICON_SRC" --out "$ICONSET_DIR/icon_32x32.png" > /dev/null 2>&1
    sips -s format png -z 64 64     "$ICON_SRC" --out "$ICONSET_DIR/icon_32x32@2x.png" > /dev/null 2>&1
    sips -s format png -z 128 128   "$ICON_SRC" --out "$ICONSET_DIR/icon_128x128.png" > /dev/null 2>&1
    sips -s format png -z 256 256   "$ICON_SRC" --out "$ICONSET_DIR/icon_128x128@2x.png" > /dev/null 2>&1
    sips -s format png -z 256 256   "$ICON_SRC" --out "$ICONSET_DIR/icon_256x256.png" > /dev/null 2>&1
    sips -s format png -z 512 512   "$ICON_SRC" --out "$ICONSET_DIR/icon_256x256@2x.png" > /dev/null 2>&1
    sips -s format png -z 512 512   "$ICON_SRC" --out "$ICONSET_DIR/icon_512x512.png" > /dev/null 2>&1
    sips -s format png -z 1024 1024 "$ICON_SRC" --out "$ICONSET_DIR/icon_512x512@2x.png" > /dev/null 2>&1
    iconutil -c icns "$ICONSET_DIR" -o "$RESOURCES_DIR/AppIcon.icns"
    rm -rf "$ICONSET_DIR"
    echo "==> AppIcon.icns bundled successfully."
fi

cat << 'EOF' > "$CONTENTS_DIR/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>macDisplayMagic</string>
    <key>CFBundleIdentifier</key>
    <string>com.nicklee.macDisplayMagic</string>
    <key>CFBundleName</key>
    <string>macDisplayMagic</string>
    <key>CFBundleDisplayName</key>
    <string>macDisplayMagic</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon.icns</string>
    <key>CFBundleIconName</key>
    <string>AppIcon</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>0.2.1</string>
    <key>CFBundleVersion</key>
    <string>0.2.1</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>macDisplayMagic uses your location solely to tag physical connection logs when external displays are plugged in (e.g. Office, Home). Your location data is stored strictly on your Mac and is NEVER transmitted, shared, or uploaded anywhere.</string>
    <key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
    <string>macDisplayMagic uses your location solely to tag physical connection logs when external displays are plugged in (e.g. Office, Home). Your location data is stored strictly on your Mac and is NEVER transmitted, shared, or uploaded anywhere.</string>
    <key>NSLocationUsageDescription</key>
    <string>macDisplayMagic uses your location solely to tag physical connection logs when external displays are plugged in (e.g. Office, Home). Your location data is stored strictly on your Mac and is NEVER transmitted, shared, or uploaded anywhere.</string>
</dict>
</plist>
EOF

touch "$APP_DIR"
echo "==> App Bundle built successfully at $APP_DIR"

INSTALL_APP=false

# Check for non-interactive --install or -i flags
for arg in "$@"; do
    if [ "$arg" == "--install" ] || [ "$arg" == "-i" ]; then
        INSTALL_APP=true
    fi
done

# If flag not passed, ask interactively if TTY is available
if [ "$INSTALL_APP" = false ] && [ -t 0 ]; then
    read -p "Do you want to copy macDisplayMagic.app to /Applications? (y/N): " choice < /dev/tty
    case "$choice" in
        [Yy]* ) INSTALL_APP=true ;;
        * ) INSTALL_APP=false ;;
    esac
fi

if [ "$INSTALL_APP" = true ]; then
    echo "==> Copying macDisplayMagic.app to /Applications/..."
    cp -R "$APP_DIR" /Applications/
    echo "==> Re-registering application icon with macOS Launch Services..."
    /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f /Applications/macDisplayMagic.app
    killall Dock Finder IconServicesAgent appstoreagent 2>/dev/null || true
    echo "==> Successfully installed macDisplayMagic.app to /Applications/macDisplayMagic.app!"
fi
