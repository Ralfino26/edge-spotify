#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$ROOT/.build"
APP_DIR="$BUILD_DIR/EdgeSpotify.app"
CONTENTS="$APP_DIR/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"
FRAMEWORKS="$CONTENTS/Frameworks"

SOURCES=(
  "$ROOT/Sources/MediaTrack.swift"
  "$ROOT/Sources/NotchGeometry.swift"
  "$ROOT/Sources/NotchShape.swift"
  "$ROOT/Sources/SpotifyController.swift"
  "$ROOT/Sources/NowPlayingController.swift"
  "$ROOT/Sources/MediaHub.swift"
  "$ROOT/Sources/SpectrumView.swift"
  "$ROOT/Sources/NotchLiveActivityView.swift"
  "$ROOT/Sources/NotchWindowController.swift"
  "$ROOT/Sources/EdgeSpotifyApp.swift"
)

rm -rf "$APP_DIR"
mkdir -p "$MACOS" "$RESOURCES" "$FRAMEWORKS"

swiftc -O -whole-module-optimization \
  -target arm64-apple-macos14.0 \
  -sdk "$(xcrun --show-sdk-path)" \
  -framework SwiftUI \
  -framework AppKit \
  -framework QuartzCore \
  -o "$MACOS/EdgeSpotify" \
  "${SOURCES[@]}"

cp "$ROOT/Info.plist" "$CONTENTS/Info.plist"
cp "$ROOT/Resources/mediaremote-adapter.pl" "$RESOURCES/"
cp -R "$ROOT/Resources/MediaRemoteAdapter.framework" "$FRAMEWORKS/"

echo "Built $APP_DIR"
