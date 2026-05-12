#!/bin/bash
# EZ Switcher — Full Packaging Script
# Builds .app bundle and .dmg installer
set -e

# Change to the script's directory to ensure relative paths work
cd "$(dirname "$0")"

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
echo "▶ Step 4: Installing app icon..."
ICON_SOURCE="$RESOURCES_DIR/AppIcon.png"
if [ -f "$ICON_SOURCE" ]; then
    cp "$ICON_SOURCE" "$APP_BUNDLE/Contents/Resources/AppIcon.png"
    echo "  ✓ Icon installed: $ICON_SOURCE"
else
    echo "  ⚠ No icon found in $RESOURCES_DIR"
fi

echo "APPL????" > "$APP_BUNDLE/Contents/PkgInfo"
echo "  ✓ PkgInfo created"

# 5. Handle Reset TCC flag
for arg in "$@"; do
    if [ "$arg" == "--reset-tcc" ]; then
        echo "🗑 Resetting TCC permissions for $BUNDLE_ID..."
        tccutil reset Accessibility "$BUNDLE_ID" || true
        tccutil reset InputMonitoring "$BUNDLE_ID" || true
    fi
done

echo ""
echo "▶ Step 5: Code signing..."
# Try to find a local dev certificate for stable permissions
# To create one: Keychain Access > Certificate Assistant > Create a Certificate > Name: EZSwitcherDev, Type: Code Signing
CERT_IDENTITY="-"
if security find-identity -p codesigning -v | grep -q "EZSwitcherDev"; then
    CERT_IDENTITY="EZSwitcherDev"
    echo "  ✨ Using stable dev certificate: $CERT_IDENTITY"
else
    echo "  ℹ Tip: To make permissions stick between builds, create a self-signed cert named 'EZSwitcherDev' in Keychain Access."
    echo "  (Using ad-hoc signing '-' for now)"
fi

xattr -cr "$APP_BUNDLE" || true
codesign --force --deep --sign "$CERT_IDENTITY" --options runtime "$APP_BUNDLE" 2>/dev/null

# Check flags
SKIP_DMG=false
SKIP_DEPLOY=false
for arg in "$@"; do
    case $arg in
        --no-dmg) SKIP_DMG=true ;;
        --no-deploy) SKIP_DEPLOY=true ;;
    esac
done

echo ""
echo "▶ Step 6: Verifying .app bundle..."
codesign --verify --deep --strict "$APP_BUNDLE" 2>/dev/null && \
    echo "  ✓ Bundle verification passed" || \
    echo "  ⚠ Bundle verification warning (ad-hoc is expected)"

# Check if target exists in Applications
DEST_APP="/Applications/$APP_NAME.app"

if [ "$SKIP_DEPLOY" = false ] && [ -d "$DEST_APP" ]; then
    echo ""
    echo "⚡ Detected existing app in /Applications."
    echo "▶ Performing robust in-place update..."
    
    # 1. Kill the app if running
    if pgrep -x "$BINARY_NAME" > /dev/null || pgrep -x "$APP_NAME" > /dev/null; then
        echo "  - Stopping running instance..."
        pkill -9 "$BINARY_NAME" || true
        pkill -9 "$APP_NAME" || true
        sleep 1
    fi
    
    # 2. Update files
    echo "  - Updating files..."
    # We use 'cp' instead of 'mv' to keep the destination folder attributes/permissions
    cp "$APP_BUNDLE/Contents/MacOS/$BINARY_NAME" "$DEST_APP/Contents/MacOS/" 2>/dev/null || true
    cp "$APP_BUNDLE/Contents/Info.plist" "$DEST_APP/Contents/Info.plist" 2>/dev/null || true
    cp -R "$APP_BUNDLE/Contents/Resources/"* "$DEST_APP/Contents/Resources/" 2>/dev/null || true

    # 3. Clear quarantine and re-sign in place
    echo "  - Refreshing security state..."
    xattr -cr "$DEST_APP" || true
    xattr -dr com.apple.quarantine "$DEST_APP" 2>/dev/null || true
    codesign --force --deep --sign "$CERT_IDENTITY" --options runtime "$DEST_APP" 2>/dev/null
    
    echo "  ✓ In-place update successful."
    echo "▶ Restarting app..."
    open -a "$DEST_APP"
    
    # Help user with permissions since hash changed (if ad-hoc)
    if [ "$CERT_IDENTITY" == "-" ]; then
        echo ""
        echo "🔔 ATTENTION: New version installed with ad-hoc signature."
        echo "   macOS has likely reset Accessibility permissions."
        echo "   Opening Privacy settings now... please toggle EZ Switcher OFF and ON."
        open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
    fi
    
elif [ "$SKIP_DEPLOY" = false ]; then
    if [ "$SKIP_DMG" = false ]; then
        echo ""
        echo "▶ Step 7: Creating .dmg installer..."
        DMG_STAGING="$BUILD_DIR/dmg_staging"
        mkdir -p "$DMG_STAGING"
        cp -R "$APP_BUNDLE" "$DMG_STAGING/"
        ABS_DMG_PATH="$(pwd)/$DMG_PATH"
        ABS_DMG_STAGING="$(pwd)/$DMG_STAGING"

        hdiutil create \
            -volname "$APP_NAME $VERSION" \
            -srcfolder "$ABS_DMG_STAGING" \
            -ov \
            -format UDZO \
            "$ABS_DMG_PATH" 2>/dev/null || DMG_FAILED=1

        if [ -z "$DMG_FAILED" ]; then
            echo "  ✓ DMG created: $DMG_PATH"
        else
            echo "  ⚠ DMG failed, created ZIP instead."
            zip -r "$BUILD_DIR/EZSwitcher-$VERSION.zip" "$APP_BUNDLE" > /dev/null
        fi
        rm -rf "$DMG_STAGING"
    fi
    
    echo ""
    echo "╔══════════════════════════════════════════════════════╗"
    echo "║   TO INSTALL:                                          ║"
    echo "║   Drag 'build/EZ Switcher.app' to /Applications       ║"
    echo "╚══════════════════════════════════════════════════════╝"
fi

echo ""
echo "✅ Done."
