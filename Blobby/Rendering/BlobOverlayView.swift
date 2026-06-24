import AppKit
import QuartzCore

final class BlobOverlayView: NSView {
    private let blobLayer = CAShapeLayer()
    private let dotLayer = CAShapeLayer()
    private var displayLink: CVDisplayLink?
    private var hasPendingDisplayLinkTick = false
    private let displayLinkLock = NSLock()
    private var layersAdded = false

    private let blobShape = BlobShape()
    private var lastFrameTime: TimeInterval = 0
    private var currentClickScale: CGFloat = 1.0

    private var cachedBlobColor: CGColor?
    private var cachedDotColor: CGColor?
    private var lastBlobColorHash: Int = 0
    private var lastDotColorHash: Int = 0
    private var wasIdle = false

    let tracker: CursorTracker
    let settings: BlobbySettings
    let springRef: SpringRef
    let cursorIsVisible: () -> Bool

    init(
        tracker: CursorTracker,
        settings: BlobbySettings,
        springRef: SpringRef,
        frame: NSRect,
        cursorIsVisible: @escaping () -> Bool = { CursorVisibility.isVisible }
    ) {
        self.tracker = tracker
        self.settings = settings
        self.springRef = springRef
        self.cursorIsVisible = cursorIsVisible
        super.init(frame: frame)
        wantsLayer = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError()
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard !layersAdded, let layer else { return }
        layersAdded = true
        layer.addSublayer(blobLayer)
        layer.addSublayer(dotLayer)
    }

    func startRendering() {
        guard displayLink == nil else { return }

        lastFrameTime = CACurrentMediaTime()
        var link: CVDisplayLink?
        guard CVDisplayLinkCreateWithActiveCGDisplays(&link) == kCVReturnSuccess,
              let link
        else {
            return
        }

        let unmanagedSelf = Unmanaged.passUnretained(self).toOpaque()
        CVDisplayLinkSetOutputCallback(link, { _, _, _, _, _, context in
            guard let context else { return kCVReturnSuccess }
            let view = Unmanaged<BlobOverlayView>.fromOpaque(context).takeUnretainedValue()

            view.displayLinkLock.lock()
            if view.hasPendingDisplayLinkTick {
                view.displayLinkLock.unlock()
                return kCVReturnSuccess
            }
            view.hasPendingDisplayLinkTick = true
            view.displayLinkLock.unlock()

            DispatchQueue.main.async {
                view.tick()
                view.displayLinkLock.lock()
                view.hasPendingDisplayLinkTick = false
                view.displayLinkLock.unlock()
            }
            return kCVReturnSuccess
        }, unmanagedSelf)

        displayLink = link
        CVDisplayLinkStart(link)
    }

    func stopRendering() {
        if let displayLink {
            CVDisplayLinkStop(displayLink)
        }
        displayLink = nil
        displayLinkLock.lock()
        hasPendingDisplayLinkTick = false
        displayLinkLock.unlock()
    }

    private func blobCGColor() -> CGColor {
        let hash = settings.blobColor.hashValue
        if hash != lastBlobColorHash || cachedBlobColor == nil {
            cachedBlobColor = NSColor(settings.blobColor).cgColor
            lastBlobColorHash = hash
        }
        return cachedBlobColor!
    }

    private func dotCGColor() -> CGColor {
        let hash = settings.dotColor.hashValue
        if hash != lastDotColorHash || cachedDotColor == nil {
            cachedDotColor = NSColor(settings.dotColor).cgColor
            lastDotColorHash = hash
        }
        return cachedDotColor!
    }

    private func tick() {
        let now = CACurrentMediaTime()
        let dt = now - lastFrameTime
        lastFrameTime = now
        guard dt > 0, dt < 0.5 else { return }

        tracker.poll()
        let screenPos = tracker.mousePosition
        guard let windowFrame = window?.frame else { return }

        if !cursorIsVisible() {
            hideLayers()
            wasIdle = false
            return
        }

        springRef.step(constants: settings.springMode.constants, target: screenPos)

        let isOnThisScreen = windowFrame.contains(screenPos)

        // Skip rendering when spring is at rest and blob is on this screen with no click animation
        if springRef.isIdle && wasIdle && !tracker.isMouseDown && abs(currentClickScale - 1.0) < 0.01 {
            return
        }

        CATransaction.begin()
        CATransaction.setDisableActions(true)

        if isOnThisScreen {
            blobLayer.isHidden = false

            let localPos = CGPoint(
                x: springRef.position.x - windowFrame.origin.x,
                y: springRef.position.y - windowFrame.origin.y
            )

            let targetScale: CGFloat = tracker.isMouseDown ? 0.8 : 1.0
            currentClickScale += (targetScale - currentClickScale) * min(CGFloat(dt) * 12.0, 1.0)

            blobLayer.path = blobShape.path(
                center: localPos,
                baseRadius: settings.blobSize / 2 * currentClickScale,
                springVelocity: springRef.velocity
            )
            blobLayer.fillColor = blobCGColor()
            blobLayer.opacity = Float(settings.opacity)

            if settings.showDotCursor {
                dotLayer.isHidden = false
                dotLayer.fillColor = dotCGColor()
                let s = settings.dotSize
                dotLayer.path = CGPath(
                    ellipseIn: CGRect(
                        x: screenPos.x - windowFrame.origin.x - s / 2,
                        y: screenPos.y - windowFrame.origin.y - s / 2,
                        width: s,
                        height: s
                    ),
                    transform: nil
                )
            } else {
                dotLayer.isHidden = true
            }
        } else {
            hideLayers()
        }

        CATransaction.commit()
        wasIdle = springRef.isIdle
    }

    private func hideLayers() {
        guard !blobLayer.isHidden || !dotLayer.isHidden else { return }

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        blobLayer.isHidden = true
        dotLayer.isHidden = true
        CATransaction.commit()
    }

    deinit {
        stopRendering()
    }
}
