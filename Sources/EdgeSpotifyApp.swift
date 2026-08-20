import AppKit
import SwiftUI

@main
struct EdgeSpotifyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra("Edge Spotify", systemImage: "music.note") {
            Button("Open player") {
                appDelegate.openPanel()
            }
            Divider()
            Text("Source")
            ForEach(MediaSource.allCases) { source in
                Button {
                    appDelegate.setSource(source)
                } label: {
                    HStack {
                        Text(source.title)
                        if appDelegate.currentSource == source {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
            Divider()
            Button("Quit Edge Spotify") {
                NSApp.terminate(nil)
            }
            .keyboardShortcut("q")
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var hub: MediaHub?
    private var notchController: NotchWindowController?

    var currentSource: MediaSource {
        hub?.source ?? .stored
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        let hub = MediaHub()
        self.hub = hub
        notchController = NotchWindowController(hub: hub)
        notchController?.show()
    }

    func openPanel() {
        notchController?.openAndFocus()
    }

    func setSource(_ source: MediaSource) {
        hub?.setSource(source)
    }
}
