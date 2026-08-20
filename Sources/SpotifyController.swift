import AppKit
import Foundation
import Observation

@Observable
@MainActor
final class SpotifyController {
    private(set) var track: MediaTrack?
    private(set) var isRunning = false
    private(set) var lastError: String?

    private var timer: Timer?
    private var notificationObserver: NSObjectProtocol?

    func start() {
        refresh()
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
        notificationObserver = DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name("com.spotify.client.PlaybackStateChanged"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        if let notificationObserver {
            DistributedNotificationCenter.default().removeObserver(notificationObserver)
            self.notificationObserver = nil
        }
    }

    func playPause() { run("playpause"); refresh() }
    func nextTrack() { run("next track"); refresh() }
    func previousTrack() { run("previous track"); refresh() }

    func openSpotify() {
        NSWorkspace.shared.open(URL(fileURLWithPath: "/Applications/Spotify.app"))
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in self?.refresh() }
    }

    func refresh() {
        let script = """
        tell application "System Events"
          set spotifyRunning to (name of processes) contains "Spotify"
        end tell
        if spotifyRunning is false then
          return "STOPPED"
        end if
        tell application "Spotify"
          set trackName to name of current track
          set artistName to artist of current track
          set artURL to artwork url of current track
          set playState to player state as string
          set pos to player position
          set dur to duration of current track
          return trackName & "\t" & artistName & "\t" & playState & "\t" & artURL & "\t" & pos & "\t" & dur
        end tell
        """

        var error: NSDictionary?
        guard let appleScript = NSAppleScript(source: script) else { return }
        let result = appleScript.executeAndReturnError(&error)

        if error != nil {
            lastError = error?["NSAppleScriptErrorMessage"] as? String
            isRunning = NSWorkspace.shared.runningApplications.contains {
                $0.bundleIdentifier == "com.spotify.client"
            }
            if !isRunning { track = nil }
            return
        }

        lastError = nil
        let raw = result.stringValue ?? ""
        if raw == "STOPPED" || raw.isEmpty {
            isRunning = false
            track = nil
            return
        }

        isRunning = true
        let parts = raw.split(separator: "\t", omittingEmptySubsequences: false).map(String.init)
        guard parts.count >= 6 else { return }
        let durationMs = Double(parts[5]) ?? 0
        track = MediaTrack(
            title: parts[0],
            artist: parts[1],
            artworkURL: URL(string: parts[3]),
            artworkData: nil,
            isPlaying: parts[2].lowercased() == "playing",
            position: Double(parts[4]) ?? 0,
            duration: durationMs > 1000 ? durationMs / 1000.0 : durationMs,
            appBundleID: "com.spotify.client"
        )
    }

    private func run(_ command: String) {
        var error: NSDictionary?
        NSAppleScript(source: "tell application \"Spotify\" to \(command)")?
            .executeAndReturnError(&error)
    }
}
