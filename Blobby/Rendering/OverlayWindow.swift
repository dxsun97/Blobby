import AppKit

final class OverlayWindow: NSWindow {
    convenience init(screen: NSScreen) {
        self.init(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        ignoresMouseEvents = true
        level = .init(Int(CGWindowLevelForKey(.maximumWindow)))
        collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        isReleasedWhenClosed = false
    }
}
