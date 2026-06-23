import CoreGraphics

struct BlobShape {
    func path(
        center: CGPoint,
        baseRadius: CGFloat,
        springVelocity: CGPoint = .zero
    ) -> CGPath {
        // springVelocity is now in px/frame (Kinet-style)
        let speed = sqrt(springVelocity.x * springVelocity.x + springVelocity.y * springVelocity.y)

        // Blobity formula exactly: min(speed * 2, 60) / 2
        let cumulativeVelocity = min(speed * 2, 60) / 2

        let path = CGMutablePath()

        if cumulativeVelocity < 0.5 {
            path.addEllipse(in: CGRect(
                x: center.x - baseRadius,
                y: center.y - baseRadius,
                width: baseRadius * 2,
                height: baseRadius * 2
            ))
            return path
        }

        let angle = atan2(springVelocity.y, springVelocity.x) + .pi

        let size = baseRadius * 2
        let r = baseRadius
        let cv = cumulativeVelocity
        let w = size
        let h = size

        let tailR = max(r - cv / 2, 2)
        let frontR = r

        let shapePath = CGMutablePath()

        shapePath.move(to: CGPoint(x: r, y: 0))

        shapePath.addArc(
            tangent1End: CGPoint(x: w + cv, y: cv / 2),
            tangent2End: CGPoint(x: w + cv, y: h + cv / 2),
            radius: tailR
        )

        shapePath.addArc(
            tangent1End: CGPoint(x: w + cv, y: h - cv / 2),
            tangent2End: CGPoint(x: cv, y: h - cv / 2),
            radius: tailR
        )

        shapePath.addArc(
            tangent1End: CGPoint(x: 0, y: h),
            tangent2End: CGPoint(x: 0, y: 0),
            radius: frontR
        )

        shapePath.addArc(
            tangent1End: CGPoint(x: 0, y: 0),
            tangent2End: CGPoint(x: w, y: 0),
            radius: frontR
        )

        shapePath.closeSubpath()

        var transform = CGAffineTransform.identity
        transform = transform.translatedBy(x: center.x, y: center.y)
        transform = transform.rotated(by: angle)
        transform = transform.translatedBy(x: -r, y: -r)

        path.addPath(shapePath, transform: transform)
        return path
    }
}
