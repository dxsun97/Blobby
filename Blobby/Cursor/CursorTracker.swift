import AppKit

final class CursorTracker {
    private(set) var mousePosition: CGPoint = .zero
    private(set) var velocity: CGPoint = .zero
    private(set) var isMouseDown: Bool = false

    private var globalMoveMonitor: Any?
    private var localMoveMonitor: Any?
    private var globalDownMonitor: Any?
    private var globalUpMonitor: Any?
    private var localDownMonitor: Any?
    private var localUpMonitor: Any?
    private var lastPosition: CGPoint = .zero
    private var lastTimestamp: TimeInterval = 0

    func start() {
        mousePosition = NSEvent.mouseLocation
        lastPosition = mousePosition
        lastTimestamp = CACurrentMediaTime()

        let moveTypes: NSEvent.EventTypeMask = [.mouseMoved, .leftMouseDragged, .rightMouseDragged, .otherMouseDragged]
        globalMoveMonitor = NSEvent.addGlobalMonitorForEvents(matching: moveTypes) { [weak self] _ in
            self?.updatePosition()
        }
        localMoveMonitor = NSEvent.addLocalMonitorForEvents(matching: moveTypes) { [weak self] event in
            self?.updatePosition()
            return event
        }

        globalDownMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.isMouseDown = true
        }
        globalUpMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseUp, .rightMouseUp]) { [weak self] _ in
            self?.isMouseDown = false
        }
        localDownMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            self?.isMouseDown = true
            return event
        }
        localUpMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseUp, .rightMouseUp]) { [weak self] event in
            self?.isMouseDown = false
            return event
        }
    }

    func stop() {
        [globalMoveMonitor, localMoveMonitor, globalDownMonitor, globalUpMonitor, localDownMonitor, localUpMonitor]
            .compactMap { $0 }
            .forEach { NSEvent.removeMonitor($0) }
        globalMoveMonitor = nil
        localMoveMonitor = nil
        globalDownMonitor = nil
        globalUpMonitor = nil
        localDownMonitor = nil
        localUpMonitor = nil
    }

    func poll() {
        updatePosition()
    }

    private func updatePosition() {
        let pos = NSEvent.mouseLocation
        let now = CACurrentMediaTime()
        let dt = now - lastTimestamp

        if dt > 0.001 {
            let invDt = CGFloat(1.0 / dt)
            let rawVx = (pos.x - lastPosition.x) * invDt
            let rawVy = (pos.y - lastPosition.y) * invDt
            velocity.x += (rawVx - velocity.x) * 0.3
            velocity.y += (rawVy - velocity.y) * 0.3
        }

        mousePosition = pos
        lastPosition = pos
        lastTimestamp = now
    }

    deinit {
        stop()
    }
}
