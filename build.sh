#!/bin/bash
# Builds Bar and assembles a runnable .app bundle (no Xcode required).
set -euo pipefail
cd "$(dirname "$0")"

CONFIG="${1:-release}"
swift build -c "$CONFIG"
BIN="$(swift build -c "$CONFIG" --show-bin-path)/Bar"

APP="build/Bar.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/Bar"
cp Resources/Info.plist "$APP/Contents/Info.plist"

# Ad-hoc sign so TCC (camera, Apple Events) can attribute prompts to the app.
codesign --force --sign - --timestamp=none "$APP" >/dev/null

echo "Built $APP"

# Launch-at-login registration is keyed to the bundle path, and this script
# recreates build/Bar.app each time. Install to /Applications for a stable one.
if [ "${2:-}" = "install" ]; then
    pkill Bar 2>/dev/null || true
    rm -rf /Applications/Bar.app
    cp -R "$APP" /Applications/Bar.app
    echo "Installed /Applications/Bar.app"
    APP=/Applications/Bar.app
fi

echo "Run:  open $APP     Stop:  pkill Bar"
