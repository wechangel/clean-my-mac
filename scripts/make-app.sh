#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "Building release binary..."
swift build -c release

APP="build/CleanMyMac.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp .build/release/CleanMyMac "$APP/Contents/MacOS/CleanMyMac"
cp Resources/Info.plist "$APP/Contents/Info.plist"

echo "Built $APP"
echo "Open it with: open $APP"
