#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/.build/EdgeSpotify.app"

"$ROOT/Scripts/build.sh"
pkill -x EdgeSpotify 2>/dev/null || true
open "$APP"
echo "Launched Edge Spotify"
