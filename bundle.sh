#!/bin/bash
set -e

APP_NAME="Blobby"
BUNDLE_DIR=".build/Blobby.app"
CONTENTS_DIR="$BUNDLE_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

# Build
swift build 2>&1

# Create bundle structure
rm -rf "$BUNDLE_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

# Copy executable
cp ".build/debug/$APP_NAME" "$MACOS_DIR/$APP_NAME"

# Copy Info.plist
cp "Blobby/Info.plist" "$CONTENTS_DIR/Info.plist"

# Generate icns from PNG
ICON_PNG="Blobby/Resources/Assets.xcassets/AppIcon.appiconset/icon_1024.png"
if [ -f "$ICON_PNG" ]; then
    ICONSET_DIR=$(mktemp -d)/AppIcon.iconset
    mkdir -p "$ICONSET_DIR"

    sips -z 16 16     "$ICON_PNG" --out "$ICONSET_DIR/icon_16x16.png" > /dev/null 2>&1
    sips -z 32 32     "$ICON_PNG" --out "$ICONSET_DIR/icon_16x16@2x.png" > /dev/null 2>&1
    sips -z 32 32     "$ICON_PNG" --out "$ICONSET_DIR/icon_32x32.png" > /dev/null 2>&1
    sips -z 64 64     "$ICON_PNG" --out "$ICONSET_DIR/icon_32x32@2x.png" > /dev/null 2>&1
    sips -z 128 128   "$ICON_PNG" --out "$ICONSET_DIR/icon_128x128.png" > /dev/null 2>&1
    sips -z 256 256   "$ICON_PNG" --out "$ICONSET_DIR/icon_128x128@2x.png" > /dev/null 2>&1
    sips -z 256 256   "$ICON_PNG" --out "$ICONSET_DIR/icon_256x256.png" > /dev/null 2>&1
    sips -z 512 512   "$ICON_PNG" --out "$ICONSET_DIR/icon_256x256@2x.png" > /dev/null 2>&1
    sips -z 512 512   "$ICON_PNG" --out "$ICONSET_DIR/icon_512x512.png" > /dev/null 2>&1
    sips -z 1024 1024 "$ICON_PNG" --out "$ICONSET_DIR/icon_512x512@2x.png" > /dev/null 2>&1

    iconutil -c icns "$ICONSET_DIR" -o "$RESOURCES_DIR/AppIcon.icns" 2>&1
    echo "✓ App icon created"
fi

# Add icon reference to Info.plist
/usr/libexec/PlistBuddy -c "Add :CFBundleIconFile string AppIcon" "$CONTENTS_DIR/Info.plist" 2>/dev/null || \
/usr/libexec/PlistBuddy -c "Set :CFBundleIconFile AppIcon" "$CONTENTS_DIR/Info.plist"

# Sign the bundle
codesign --force --sign - --identifier com.blobby.app --deep "$BUNDLE_DIR" > /dev/null 2>&1

echo "✓ Built $BUNDLE_DIR"
echo "  Run with: open $BUNDLE_DIR"
