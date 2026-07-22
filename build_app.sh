#!/bin/bash
set -e

echo "==> Building macDisplayMagic executable..."
swift build -c release

APP_DIR="dist/macDisplayMagic.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"

echo "==> Creating Application Bundle ($APP_DIR)..."
mkdir -p "$MACOS_DIR"

cp .build/release/macDisplayMagic "$MACOS_DIR/macDisplayMagic"

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
