import Foundation

struct MediaTrack: Equatable {
    var title: String
    var artist: String
    var artworkURL: URL?
    var artworkData: Data?
    var isPlaying: Bool
    var position: Double
    var duration: Double
    var appBundleID: String
}

enum MediaSource: String, CaseIterable, Identifiable {
    case nowPlaying
    case spotify

    var id: String { rawValue }

    var title: String {
        switch self {
        case .nowPlaying: "Now Playing"
        case .spotify: "Spotify"
        }
    }

    static var stored: MediaSource {
        get {
            MediaSource(rawValue: UserDefaults.standard.string(forKey: "mediaSource") ?? "")
                ?? .nowPlaying
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "mediaSource")
        }
    }
}
