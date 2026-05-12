#!/bin/bash
# EZ Switcher — Full Packaging Script
# Builds .app bundle and .dmg installer
set -e

# ─── CONFIG ──────────────────────────────────────────────────
APP_NAME="EZ Switcher"
BUNDLE_ID="com.ezswitcher.app"
VERSION="1.0.0"
SOURCE_DIR="Sources/EZSwitcher"
RESOURCES_DIR="Resources"
BUILD_DIR="build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
DMG_PATH="$BUILD_DIR/EZSwitcher-$VERSION.dmg"
BINARY_NAME="EZSwitcher"
# ─────────────────────────────────────────────────────────────

echo ""
echo "╔══════════════════════════════════════╗"
echo "║   EZ Switcher — Package Script       ║"
echo "║   Version: $VERSION                      ║"
echo "╚══════════════════════════════════════╝"
echo ""

# Clean build dir
rm -rf "$BUILD_DIR"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

echo "▶ Step 1: Collecting Swift source files..."
FILES=$(ls $SOURCE_DIR/*.swift | grep -v "Tests.swift")
echo "  Files: $(echo $FILES | wc -w | tr -d ' ') source files found"

echo ""
echo "▶ Step 2: Compiling binary (Debug mode for speed)..."
swiftc \
    -o "$APP_BUNDLE/Contents/MacOS/$BINARY_NAME" \
    $FILES \
    -framework Cocoa \
    -framework Carbon \
    -framework NaturalLanguage \
    -framework AppKit \
    -framework CoreGraphics \
    -sdk $(xcrun --show-sdk-path) \
    2>&1

if [ $? -ne 0 ]; then
    echo "✗ Compilation failed."
    exit 1
fi
echo "  ✓ Binary compiled: $APP_BUNDLE/Contents/MacOS/$BINARY_NAME"

echo ""
echo "▶ Step 3: Copying Info.plist..."
cp "$RESOURCES_DIR/Info.plist" "$APP_BUNDLE/Contents/Info.plist"
echo "  ✓ Info.plist installed"

echo ""
echo "▶ Step 4: Generating app icon (simple programmatic icon)..."
# Create a simple icon using sips if no .icns available
ICON_SOURCE="$RESOURCES_DIR/AppIcon.png"
if [ -f "$ICON_SOURCE" ]; then
    iconutil -c icns -o "$APP_BUNDLE/Contents/Resources/AppIcon.icns" "$RESOURCES_DIR/AppIcon.iconset" 2>/dev/null || \
    cp "$ICON_SOURCE" "$APP_BUNDLE/Contents/Resources/AppIcon.png"
    echo "  ✓ Icon installed"
else
    echo "  ⚠ No icon found, using system default"
fi

echo ""
echo "▶ Step 5: Ad-hoc code signing (for local testing)..."
codesign --force --deep --sign - "$APP_BUNDLE" 2>&1
if [ $? -eq 0 ]; then
    echo "  ✓ App signed (ad-hoc, for local testing)"
else
    echo "  ⚠ Code signing failed — app may still run but Gatekeeper will warn"
fi

echo ""
echo "▶ Step 6: Verifying .app bundle..."
codesign --verify --deep --strict "$APP_BUNDLE" 2>/dev/null && \
    echo "  ✓ Bundle verification passed" || \
    echo "  ⚠ Bundle verification warning (ad-hoc is expected)"

ls -la "$APP_BUNDLE/Contents/MacOS/"

echo ""
echo "▶ Step 7: Creating .dmg installer..."

# Create a temporary folder for DMG contents
DMG_STAGING="$BUILD_DIR/dmg_staging"
mkdir -p "$DMG_STAGING"
cp -R "$APP_BUNDLE" "$DMG_STAGING/"

# Create DMG
hdiutil create \
    -volname "$APP_NAME $VERSION" \
    -srcfolder "$DMG_STAGING" \
    -ov \
    -format UDZO \
    "$DMG_PATH" 2>&1

if [ $? -eq 0 ]; then
    DMG_SIZE=$(du -sh "$DMG_PATH" | cut -f1)
    echo "  ✓ DMG created: $DMG_PATH ($DMG_SIZE)"
else
    echo "  ✗ DMG creation failed"
    exit 1
fi

# Cleanup staging
rm -rf "$DMG_STAGING"

echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║   ✅ BUILD COMPLETE                                   ║"
echo "╠══════════════════════════════════════════════════════╣"
echo "║                                                       ║"
APP_PATH_DISPLAY="$BUILD_DIR/$APP_NAME.app"
echo "║  .app  → $APP_BUNDLE"
echo "║  .dmg  → $DMG_PATH"
echo "║                                                       ║"
echo "║  TO INSTALL:                                          ║"
echo "║  1. Open EZSwitcher-$VERSION.dmg                     ║"
echo "║  2. Drag 'EZ Switcher.app' to /Applications          ║"
echo "║  3. System Settings → Privacy & Security:             ║"
echo "║     → Accessibility → Enable EZ Switcher             ║"
echo "║     → Input Monitoring → Enable EZ Switcher          ║"
echo "║                                                       ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""
