#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$ROOT/.build"
APP_DIR="$BUILD_DIR/EdgeSpotify.app"
DERIVED="$BUILD_DIR/DerivedData"
ENTITLEMENTS_SRC="$ROOT/boringNotch/boringNotch.entitlements"
ENTITLEMENTS_EXPANDED="$BUILD_DIR/EdgeSpotify.entitlements"

mkdir -p "$BUILD_DIR"

xcodebuild \
  -project "$ROOT/boringNotch.xcodeproj" \
  -scheme boringNotch \
  -configuration Release \
  -destination 'platform=macOS' \
  -derivedDataPath "$DERIVED" \
  ONLY_ACTIVE_ARCH=YES \
  build

BUILT="$DERIVED/Build/Products/Release/boringNotch.app"
rm -rf "$APP_DIR"
cp -R "$BUILT" "$APP_DIR"

# Expand Xcode vars for a valid manual codesign entitlements plist.
python3 - "$ENTITLEMENTS_SRC" "$ENTITLEMENTS_EXPANDED" <<'PY'
import plistlib
import sys
from pathlib import Path

src, dst = map(Path, sys.argv[1:3])
data = plistlib.loads(src.read_bytes())
key = "com.apple.security.temporary-exception.mach-lookup.global-name"
if key in data:
    data[key] = [
        s.replace("$(PRODUCT_BUNDLE_IDENTIFIER)", "com.byralf.edgespotify")
        for s in data[key]
    ]
dst.write_bytes(plistlib.dumps(data))
PY

# Ad-hoc resign so embedded frameworks load under hardened runtime.
codesign --force --deep --sign - --timestamp=none --options runtime \
  --entitlements "$ENTITLEMENTS_EXPANDED" \
  "$APP_DIR"

echo "Built $APP_DIR"
