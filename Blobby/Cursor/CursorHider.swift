import AppKit

final class CursorHider {
    private var isHidden = false
    private var isPaused = false
    private var hideCount = 0
    private var moveMonitor: Any?

    func hide() {
        guard !isHidden else { return }
        isPaused = false
        NSCursor.hide()
        hideCount = 1
        isHidden = true

        moveMonitor = NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { [weak self] _ in
            guard let self, self.isHidden, !self.isPaused else { return }
            if self.hideCount < 8 {
                NSCursor.hide()
                self.hideCount += 1
            }
        }
    }

    func unhide() {
        guard isHidden else { return }
        if let monitor = moveMonitor {
            NSEvent.removeMonitor(monitor)
            moveMonitor = nil
        }
        for _ in 0..<hideCount {
            NSCursor.unhide()
        }
        hideCount = 0
        isHidden = false
        isPaused = false
    }

    func pause() {
        guard isHidden, !isPaused else { return }
        isPaused = true
        for _ in 0..<hideCount {
            NSCursor.unhide()
        }
        hideCount = 0
    }

    func resume() {
        guard isHidden, isPaused else { return }
        isPaused = false
        NSCursor.hide()
        hideCount = 1
    }

    deinit {
        unhide()
    }
}
