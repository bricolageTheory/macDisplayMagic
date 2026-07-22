#!/bin/bash
set -e

echo "==> Building macDisplayMagic executable..."
swift build -c release

APP_DIR="dist/macDisplayMagic.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "==> Creating Application Bundle ($APP_DIR)..."
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

cp .build/release/macDisplayMagic "$MACOS_DIR/macDisplayMagic"

# Check for PNG application icon in Resources/ or project root
ICON_SRC=""
if [ -f "Resources/AppIcon.png" ]; then
    ICON_SRC="Resources/AppIcon.png"
elif [ -f "AppIcon.png" ]; then
    ICON_SRC="AppIcon.png"
fi

if [ -n "$ICON_SRC" ]; then
    echo "==> Converting $ICON_SRC to macOS AppIcon.icns..."
    ICONSET_DIR="dist/AppIcon.iconset"
    mkdir -p "$ICONSET_DIR"
    sips -z 16 16     "$ICON_SRC" --out "$ICONSET_DIR/icon_16x16.png" > /dev/null 2>&1 || true
    sips -z 32 32     "$ICON_SRC" --out "$ICONSET_DIR/icon_16x16@2x.png" > /dev/null 2>&1 || true
    sips -z 32 32     "$ICON_SRC" --out "$ICONSET_DIR/icon_32x32.png" > /dev/null 2>&1 || true
    sips -z 64 64     "$ICON_SRC" --out "$ICONSET_DIR/icon_32x32@2x.png" > /dev/null 2>&1 || true
    sips -z 128 128   "$ICON_SRC" --out "$ICONSET_DIR/icon_128x128.png" > /dev/null 2>&1 || true
    sips -z 256 256   "$ICON_SRC" --out "$ICONSET_DIR/icon_128x128@2x.png" > /dev/null 2>&1 || true
    sips -z 256 256   "$ICON_SRC" --out "$ICONSET_DIR/icon_256x256.png" > /dev/null 2>&1 || true
    sips -z 512 512   "$ICON_SRC" --out "$ICONSET_DIR/icon_256x256@2x.png" > /dev/null 2>&1 || true
    sips -z 512 512   "$ICON_SRC" --out "$ICONSET_DIR/icon_512x512.png" > /dev/null 2>&1 || true
    sips -z 1024 1024 "$ICON_SRC" --out "$ICONSET_DIR/icon_512x512@2x.png" > /dev/null 2>&1 || true
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
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

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
    echo "==> Successfully installed macDisplayMagic.app to /Applications/macDisplayMagic.app!"
fi
