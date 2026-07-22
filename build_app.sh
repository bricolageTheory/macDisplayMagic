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
