# Edge Spotify (Boring Notch fork)

Spotify / system **Now Playing**-only fork of [Boring Notch](https://github.com/TheBoredTeam/boring.notch) (GPL-3.0).

Keeps Boring Notch’s exact notch chrome and music live-activity / open-notch player UI, wired to:

- **Spotify** (`SpotifyController`)
- **Now Playing** (`NowPlayingController` + `mediaremote-adapter`)

Calendar, Shelf, OSD/HUD, Webcam, Battery, Downloads, YouTube Music, Apple Music as a selectable source, and the XPC helper are removed.

## Build

Requires Xcode / `xcodebuild` on macOS:

```bash
xcodebuild -project boringNotch.xcodeproj -scheme boringNotch -configuration Debug -destination 'platform=macOS' -derivedDataPath /tmp/edge-spotify-dd build
```

Run:

```bash
open /tmp/edge-spotify-dd/Build/Products/Debug/boringNotch.app
```
