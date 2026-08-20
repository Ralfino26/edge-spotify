# Edge Spotify

A minimal macOS notch app for Spotify / system Now Playing.

Fork of [Boring Notch](https://github.com/TheBoredTeam/boring.notch) — same notch chrome and music live-activity, stripped to music only.

Hover the **notch** to open the player. Control Spotify or whatever is in system Now Playing. It lives in the menu bar (no Dock icon).

## Requirements

- macOS 14+
- Xcode (`xcode-select --install` is not enough; full Xcode is required)

## Run

```bash
./Scripts/run.sh
```

Build only:

```bash
./Scripts/build.sh
open .build/EdgeSpotify.app
```

For a stable login item, install somewhere lasting (recommended — `./Scripts/run.sh` does this):

```bash
./Scripts/build.sh
cp -R .build/EdgeSpotify.app /Applications/
open /Applications/EdgeSpotify.app
```

## Use

1. Play music in Spotify (or another app that reports Now Playing)
2. Hover the MacBook notch to open the player
3. Menu bar → **Edge Spotify** → Quit

### Open at Login

On first launch, Edge Spotify registers itself to start when you log in. Toggle it anytime via menu bar → **Open at Login**.

macOS may ask for permission under **System Settings → General → Login Items**.

## Stack

Native Swift + SwiftUI (Boring Notch fork) + `mediaremote-adapter` for system Now Playing.

## License

GPL-3.0 (upstream Boring Notch)
