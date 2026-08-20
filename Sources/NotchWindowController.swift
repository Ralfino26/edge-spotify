import AppKit
import QuartzCore
import SwiftUI

final class KeyablePanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

/// Pins a Boring Notch–style live activity to the real Mac notch.
@MainActor
final class NotchWindowController: NSObject {
    static let slideDuration: CFTimeInterval = 0.42
    static let collapseGrace: TimeInterval = 0.14

    private let hub: MediaHub
    private var panel: KeyablePanel!
    private var hostingView: NSHostingView<NotchLiveActivityView>!
    private var isExpanded = false
    private var isAnimating = false
    private var collapseWorkItem: DispatchWorkItem?
    private var globalMouseMonitor: Any?
    private var localMouseMonitor: Any?
    private var screenObserver: NSObjectProtocol?
    private var isPointerInside = false
    private var closedSize = CGSize(width: 220, height: 32)

    init(hub: MediaHub) {
        self.hub = hub
        super.init()
        closedSize = NotchGeometry.closedLiveActivitySize()
        buildPanel()
        observeScreenChanges()
        startMouseMonitor()
        collapse(animated: false)
    }

    deinit {
        if let globalMouseMonitor { NSEvent.removeMonitor(globalMouseMonitor) }
        if let localMouseMonitor { NSEvent.removeMonitor(localMouseMonitor) }
        if let screenObserver { NotificationCenter.default.removeObserver(screenObserver) }
    }

    func show() {
        layoutPanel(expanded: isExpanded, animated: false)
        panel.ignoresMouseEvents = false
        panel.orderFrontRegardless()
    }

    func openAndFocus() {
        expand(activate: true)
    }

    private func buildPanel() {
        panel = KeyablePanel(
            contentRect: NSRect(origin: .zero, size: closedSize),
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        // Match Boring Notch: above menu bar, joins all spaces
        panel.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.mainMenuWindow)) + 3)
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        panel.isMovable = false
        panel.animationBehavior = .none
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.appearance = NSAppearance(named: .darkAqua)

        hostingView = NSHostingView(rootView: makeRoot())
        hostingView.frame = panel.contentView?.bounds ?? .zero
        hostingView.autoresizingMask = [.width, .height]
        panel.contentView = hostingView
        panel.contentView?.wantsLayer = true
        panel.contentView?.layer?.backgroundColor = NSColor.clear.cgColor
    }

    private func makeRoot() -> NotchLiveActivityView {
        NotchLiveActivityView(hub: hub, isExpanded: isExpanded, closedSize: closedSize)
    }

    private func refreshRoot() {
        hostingView.rootView = makeRoot()
    }

    private func observeScreenChanges() {
        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self, !self.isAnimating else { return }
            self.closedSize = NotchGeometry.closedLiveActivitySize(on: self.preferredScreen())
            self.layoutPanel(expanded: self.isExpanded, animated: false)
            self.refreshRoot()
        }
    }

    private func startMouseMonitor() {
        globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved, .leftMouseDragged]) { [weak self] _ in
            self?.handleMouseLocation(NSEvent.mouseLocation)
        }
        localMouseMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.mouseMoved, .leftMouseDragged, .leftMouseDown]
        ) { [weak self] event in
            self?.handleMouseLocation(NSEvent.mouseLocation)
            return event
        }
    }

    private func handleMouseLocation(_ point: NSPoint) {
        guard !isAnimating else { return }
        let hitPad: CGFloat = isExpanded ? 12 : 4
        let inside = panel.frame.insetBy(dx: -hitPad, dy: -hitPad).contains(point)
        let wasInside = isPointerInside
        isPointerInside = inside

        if isPointerInside {
            cancelCollapse()
            if !isExpanded { expand(activate: false) }
        } else if isExpanded && (wasInside || !isPointerInside) {
            scheduleCollapse()
        }
    }

    private func preferredScreen() -> NSScreen? {
        panel.screen ?? NSScreen.main ?? NSScreen.screens.first
    }

    private func expand(activate: Bool) {
        cancelCollapse()
        let wasExpanded = isExpanded
        isExpanded = true
        refreshRoot()
        layoutPanel(expanded: true, animated: !wasExpanded)
        if activate {
            NSApp.activate(ignoringOtherApps: true)
            panel.makeKeyAndOrderFront(nil)
        } else {
            panel.orderFrontRegardless()
        }
    }

    private func collapse(animated: Bool) {
        cancelCollapse()
        guard isExpanded || animated == false else { return }
        isExpanded = false
        isPointerInside = false
        if panel.isKeyWindow { panel.resignKey() }
        refreshRoot()
        layoutPanel(expanded: false, animated: animated)
    }

    private func scheduleCollapse() {
        guard collapseWorkItem == nil, !isAnimating else { return }
        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.collapseWorkItem = nil
            guard !self.isPointerInside, self.isExpanded, !self.isAnimating else { return }
            self.collapse(animated: true)
        }
        collapseWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.collapseGrace, execute: work)
    }

    private func cancelCollapse() {
        collapseWorkItem?.cancel()
        collapseWorkItem = nil
    }

    private func layoutPanel(expanded: Bool, animated: Bool) {
        guard let screen = preferredScreen() else { return }
        let display = screen.frame
        closedSize = NotchGeometry.closedLiveActivitySize(on: screen)

        let width = expanded
            ? min(NotchGeometry.openSize.width, display.width - 48)
            : closedSize.width
        let height = expanded
            ? min(NotchGeometry.openSize.height, display.height - 120)
            : closedSize.height
        let x = display.midX - width / 2
        let y = display.maxY - height
        let target = NSRect(x: x, y: y, width: width, height: height)

        if animated {
            isAnimating = true
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = Self.slideDuration
                context.timingFunction = CAMediaTimingFunction(controlPoints: 0.16, 1.0, 0.3, 1.0)
                context.allowsImplicitAnimation = true
                panel.animator().setFrame(target, display: true)
            }, completionHandler: { [weak self] in
                self?.isAnimating = false
            })
        } else {
            panel.setFrame(target, display: true)
        }
    }
}
