import AppKit
import Foundation

enum NotchGeometry {
    /// Physical notch width from menu-bar auxiliary areas (Boring Notch approach).
    @MainActor
    static func closedSize(on screen: NSScreen? = NSScreen.main) -> CGSize {
        guard let screen else {
            return CGSize(width: 200, height: 32)
        }

        var width: CGFloat = 185
        if let left = screen.auxiliaryTopLeftArea?.width,
           let right = screen.auxiliaryTopRightArea?.width
        {
            width = screen.frame.width - left - right + 4
        }

        let height = screen.safeAreaInsets.top > 0 ? screen.safeAreaInsets.top : 32
        return CGSize(width: width, height: height)
    }

    /// Closed live-activity total width: wing + notch + wing.
    static let wingWidth: CGFloat = 36
    static let liveActivityEdgeMargin: CGFloat = 8

    @MainActor
    static func closedLiveActivitySize(on screen: NSScreen? = NSScreen.main) -> CGSize {
        let notch = closedSize(on: screen)
        let width = notch.width + (2 * wingWidth) + (2 * liveActivityEdgeMargin)
        return CGSize(width: width, height: notch.height)
    }

    static let openSize = CGSize(width: 420, height: 168)
}
