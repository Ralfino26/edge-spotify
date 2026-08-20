#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/.build/EdgeSpotify.app"
INSTALL="/Applications/EdgeSpotify.app"

"$ROOT/Scripts/build.sh"

# Prefer a lasting install so login items survive reboot (/tmp and .build do not).
pkill -x boringNotch 2>/dev/null || true
rm -rf "$INSTALL"
cp -R "$APP" "$INSTALL"
open "$INSTALL"

echo "Installed and launched $INSTALL"
