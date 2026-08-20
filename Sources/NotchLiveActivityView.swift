import AppKit
import SwiftUI

/// Closed = Boring Notch–style music live activity in the real notch.
/// Expanded = full mini player on hover.
struct NotchLiveActivityView: View {
    @Bindable var hub: MediaHub
    var isExpanded: Bool
    var closedSize: CGSize

    var body: some View {
        ZStack(alignment: .top) {
            Color.black

            if isExpanded {
                expandedPlayer
                    .padding(16)
                    .transition(.opacity.combined(with: .scale(scale: 0.98, anchor: .top)))
            } else {
                closedLiveActivity
                    .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .clipShape(
            NotchShape(
                topCornerRadius: isExpanded ? 19 : 6,
                bottomCornerRadius: isExpanded ? 24 : 14
            )
        )
        .animation(.easeOut(duration: 0.28), value: isExpanded)
        .environment(\.colorScheme, .dark)
        .onAppear { hub.start() }
        .onDisappear { hub.stop() }
        .onReceive(Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()) { _ in
            hub.tick()
        }
    }

    /// Album art | physical notch gap | spectrum — always parked on the Mac notch.
    private var closedLiveActivity: some View {
        let artSize = max(14, closedSize.height - 12)

        return HStack(spacing: 0) {
            artwork(size: artSize, cornerRadius: 4)
                .frame(width: NotchGeometry.wingWidth, height: closedSize.height)
                .contentShape(Rectangle())
                .onTapGesture { hub.playPause() }

            Color.black
                .frame(maxWidth: .infinity)
                .frame(height: closedSize.height)

            HStack {
                SpectrumView(isPlaying: hub.track?.isPlaying == true)
            }
            .frame(width: NotchGeometry.wingWidth, height: closedSize.height)
            .contentShape(Rectangle())
            .onTapGesture { hub.playPause() }
        }
        .frame(height: closedSize.height)
        .padding(.horizontal, NotchGeometry.liveActivityEdgeMargin)
    }

    private var expandedPlayer: some View {
        Group {
            if let track = hub.track {
                HStack(spacing: 16) {
                    artwork(size: 88, cornerRadius: 14)

                    VStack(alignment: .leading, spacing: 10) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(track.title)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.92))
                                .lineLimit(1)
                            Text(track.artist)
                                .font(.system(size: 12.5))
                                .foregroundStyle(.white.opacity(0.45))
                                .lineLimit(1)
                        }
                        progress(track)
                        controls(isPlaying: track.isPlaying)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                VStack(spacing: 12) {
                    Text(idleTitle)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.55))
                    if hub.source == .spotify && !hub.isAvailable {
                        Button("Open Spotify") { hub.openSpotify() }
                            .buttonStyle(.plain)
                            .foregroundStyle(.white.opacity(0.85))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private var idleTitle: String {
        if let statusMessage = hub.statusMessage, !statusMessage.isEmpty { return statusMessage }
        switch hub.source {
        case .spotify: return hub.isAvailable ? "Nothing playing" : "Spotify is closed"
        case .nowPlaying: return "Nothing playing"
        }
    }

    @ViewBuilder
    private func artwork(size: CGFloat, cornerRadius: CGFloat) -> some View {
        let track = hub.track
        Group {
            if let data = track?.artworkData, let image = NSImage(data: data) {
                Image(nsImage: image).resizable().scaledToFill()
            } else if let url = track?.artworkURL {
                AsyncImage(url: url) { phase in
                    if case .success(let image) = phase {
                        image.resizable().scaledToFill()
                    } else {
                        artPlaceholder
                    }
                }
            } else {
                artPlaceholder
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    private var artPlaceholder: some View {
        RoundedRectangle(cornerRadius: 4, style: .continuous)
            .fill(Color.white.opacity(0.08))
            .overlay(Image(systemName: "music.note").font(.system(size: 9)).foregroundStyle(.white.opacity(0.25)))
    }

    private func progress(_ track: MediaTrack) -> some View {
        let p = track.duration > 0 ? min(max(track.position / track.duration, 0), 1) : 0
        return VStack(spacing: 4) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.08))
                    Capsule().fill(Color.white.opacity(0.55)).frame(width: geo.size.width * p)
                }
            }
            .frame(height: 3)
            HStack {
                Text(formatTime(track.position))
                Spacer()
                Text(formatTime(track.duration))
            }
            .font(.system(size: 10, weight: .medium).monospacedDigit())
            .foregroundStyle(.white.opacity(0.28))
        }
    }

    private func controls(isPlaying: Bool) -> some View {
        HStack(spacing: 22) {
            Button(action: hub.previousTrack) {
                Image(systemName: "backward.fill").font(.system(size: 13, weight: .semibold))
            }
            Button(action: hub.playPause) {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .frame(width: 28, height: 28)
            }
            Button(action: hub.nextTrack) {
                Image(systemName: "forward.fill").font(.system(size: 13, weight: .semibold))
            }
        }
        .buttonStyle(.plain)
        .foregroundStyle(.white.opacity(0.85))
        .frame(maxWidth: .infinity)
    }

    private func formatTime(_ seconds: Double) -> String {
        let total = max(Int(seconds.rounded()), 0)
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}
