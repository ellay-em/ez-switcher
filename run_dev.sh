#!/bin/bash
# EZ Switcher — Dev Run Script
# Builds the binary and runs it directly from the build folder.

set -e
cd "$(dirname "$0")"

APP_NAME="EZ Switcher"
BUILD_DIR="build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"

# 1. Build using the existing package script (Step 1-6 only)
# We can just run the package script and ignore the DMG part
echo "🔨 Building app..."
./package_app.sh --no-dmg --no-deploy

# 2. Kill existing process
echo "🛑 Stopping EZ Switcher if running..."
pkill -x "EZSwitcher" || true
sleep 0.5

# 3. Clear quarantine and sign (already done by package_app.sh, but let's be sure)
xattr -dr com.apple.quarantine "$APP_BUNDLE" 2>/dev/null || true

# 4. Open the app
echo "🚀 Launching from $APP_BUNDLE..."
open "$APP_BUNDLE"

echo ""
echo "💡 TIP: If the app doesn't start, check 'System Settings > Privacy & Security > Accessibility'."
echo "   Since the binary changed, you likely need to toggle EZ Switcher OFF and ON again."
echo ""
