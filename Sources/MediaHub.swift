import Foundation
import Observation

@Observable
@MainActor
final class MediaHub {
    private(set) var source: MediaSource
    private(set) var track: MediaTrack?
    private(set) var isAvailable = false
    private(set) var statusMessage: String?

    private let spotify = SpotifyController()
    private let nowPlaying: NowPlayingController?

    init() {
        source = .stored
        nowPlaying = NowPlayingController()
    }

    func setSource(_ newSource: MediaSource) {
        guard newSource != source else { return }
        source = newSource
        MediaSource.stored = newSource
        applySource(newSource)
    }

    func start() {
        applySource(source)
    }

    func stop() {
        spotify.stop()
        nowPlaying?.stop()
    }

    func playPause() {
        switch source {
        case .spotify: spotify.playPause()
        case .nowPlaying: nowPlaying?.playPause()
        }
        tick()
    }

    func nextTrack() {
        switch source {
        case .spotify: spotify.nextTrack()
        case .nowPlaying: nowPlaying?.nextTrack()
        }
        tick()
    }

    func previousTrack() {
        switch source {
        case .spotify: spotify.previousTrack()
        case .nowPlaying: nowPlaying?.previousTrack()
        }
        tick()
    }

    func openSpotify() { spotify.openSpotify() }

    func tick() {
        switch source {
        case .spotify:
            track = spotify.track
            isAvailable = spotify.isRunning
            statusMessage = spotify.lastError
        case .nowPlaying:
            track = nowPlaying?.track
            isAvailable = nowPlaying?.isActive == true
            statusMessage = nowPlaying?.lastError
        }
    }

    private func applySource(_ source: MediaSource) {
        spotify.stop()
        nowPlaying?.stop()
        switch source {
        case .spotify:
            spotify.start()
            statusMessage = nil
        case .nowPlaying:
            if let nowPlaying {
                nowPlaying.start()
                statusMessage = nil
            } else {
                statusMessage = "Now Playing unavailable on this Mac"
            }
        }
        tick()
    }
}
