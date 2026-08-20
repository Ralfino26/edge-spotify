import SwiftUI

/// Simple bouncing bars like Boring Notch's closed-state spectrum.
struct SpectrumView: View {
    var isPlaying: Bool
    var tint: Color = .gray

    @State private var levels: [CGFloat] = [0.35, 0.7, 0.45, 0.9, 0.55]

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.12, paused: !isPlaying)) { timeline in
            HStack(alignment: .bottom, spacing: 2) {
                ForEach(0..<levels.count, id: \.self) { index in
                    Capsule()
                        .fill(tint.opacity(0.85))
                        .frame(width: 2.5, height: max(3, 12 * animatedLevel(index, at: timeline.date)))
                }
            }
            .frame(width: 18, height: 12, alignment: .bottom)
        }
    }

    private func animatedLevel(_ index: Int, at date: Date) -> CGFloat {
        guard isPlaying else { return levels[index] * 0.35 }
        let t = date.timeIntervalSinceReferenceDate
        let wave = (sin(t * 8 + Double(index) * 1.3) + 1) / 2
        return 0.25 + CGFloat(wave) * 0.75
    }
}
