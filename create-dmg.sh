#!/bin/bash
set -e

APP_NAME="Blobby"
VERSION="${1:-1.0.0}"
CONFIG="release"

BUNDLE_DIR=".build/Blobby.app"
CONTENTS_DIR="$BUNDLE_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
DMG_NAME="Blobby-${VERSION}-universal.dmg"
DMG_TEMP="Blobby-temp.dmg"

echo "==> Building $APP_NAME v$VERSION (universal)"
swift build -c "$CONFIG" --arch x86_64 --arch arm64 2>&1

echo "==> Creating app bundle"
rm -rf "$BUNDLE_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

cp ".build/apple/Products/Release/$APP_NAME" "$MACOS_DIR/$APP_NAME"
cp "Blobby/Info.plist" "$CONTENTS_DIR/Info.plist"

/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$CONTENTS_DIR/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $VERSION" "$CONTENTS_DIR/Info.plist"

ICON_PNG="Blobby/Resources/Assets.xcassets/AppIcon.appiconset/icon_1024.png"
if [ -f "$ICON_PNG" ]; then
    ICONSET_DIR=$(mktemp -d)/AppIcon.iconset
    mkdir -p "$ICONSET_DIR"

    sips -z 16 16     "$ICON_PNG" --out "$ICONSET_DIR/icon_16x16.png"       > /dev/null 2>&1
    sips -z 32 32     "$ICON_PNG" --out "$ICONSET_DIR/icon_16x16@2x.png"    > /dev/null 2>&1
    sips -z 32 32     "$ICON_PNG" --out "$ICONSET_DIR/icon_32x32.png"       > /dev/null 2>&1
    sips -z 64 64     "$ICON_PNG" --out "$ICONSET_DIR/icon_32x32@2x.png"    > /dev/null 2>&1
    sips -z 128 128   "$ICON_PNG" --out "$ICONSET_DIR/icon_128x128.png"     > /dev/null 2>&1
    sips -z 256 256   "$ICON_PNG" --out "$ICONSET_DIR/icon_128x128@2x.png"  > /dev/null 2>&1
    sips -z 256 256   "$ICON_PNG" --out "$ICONSET_DIR/icon_256x256.png"     > /dev/null 2>&1
    sips -z 512 512   "$ICON_PNG" --out "$ICONSET_DIR/icon_256x256@2x.png"  > /dev/null 2>&1
    sips -z 512 512   "$ICON_PNG" --out "$ICONSET_DIR/icon_512x512.png"     > /dev/null 2>&1
    sips -z 1024 1024 "$ICON_PNG" --out "$ICONSET_DIR/icon_512x512@2x.png"  > /dev/null 2>&1

    iconutil -c icns "$ICONSET_DIR" -o "$RESOURCES_DIR/AppIcon.icns"
    /usr/libexec/PlistBuddy -c "Add :CFBundleIconFile string AppIcon" "$CONTENTS_DIR/Info.plist" 2>/dev/null || \
    /usr/libexec/PlistBuddy -c "Set :CFBundleIconFile AppIcon" "$CONTENTS_DIR/Info.plist"
    echo "  ✓ App icon"
fi

# Sign the bundle
codesign --force --sign - --identifier com.blobby.app --deep "$BUNDLE_DIR" > /dev/null 2>&1
echo "  ✓ Code signed"

echo "  ✓ App bundle at $BUNDLE_DIR"

echo "==> Creating DMG"

DMG_DIR=$(mktemp -d)
cp -R "$BUNDLE_DIR" "$DMG_DIR/"
ln -s /Applications "$DMG_DIR/Applications"

BG_IMG="assets/dmg_background.png"
if [ -f "$BG_IMG" ]; then
    mkdir -p "$DMG_DIR/.background"
    cp "$BG_IMG" "$DMG_DIR/.background/background.png"
fi

rm -f "$DMG_TEMP" "$DMG_NAME"
hdiutil create -volname "Blobby" \
    -srcfolder "$DMG_DIR" \
    -ov -format UDRW \
    -size 10m \
    "$DMG_TEMP" > /dev/null 2>&1

MOUNT_DIR=$(hdiutil attach -readwrite -noverify "$DMG_TEMP" | grep "/Volumes/" | awk '{print $NF}')

osascript <<APPLESCRIPT
tell application "Finder"
    tell disk "Blobby"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set bounds of container window to {200, 200, 700, 540}
        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to 80
        set background picture of viewOptions to file ".background:background.png"
        set position of item "Blobby.app" of container window to {125, 170}
        set position of item "Applications" of container window to {375, 170}
        close
        open
        update without registering applications
        delay 1
        close
    end tell
end tell
APPLESCRIPT

hdiutil detach "$MOUNT_DIR" > /dev/null 2>&1
hdiutil convert "$DMG_TEMP" -format UDZO -o "$DMG_NAME" > /dev/null 2>&1
rm -f "$DMG_TEMP"
rm -rf "$DMG_DIR"

DMG_SIZE=$(du -h "$DMG_NAME" | cut -f1 | xargs)
echo "  ✓ $DMG_NAME ($DMG_SIZE)"
echo ""
echo "Done! Distribute $DMG_NAME"
