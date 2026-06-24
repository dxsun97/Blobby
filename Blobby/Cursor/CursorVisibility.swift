import AppKit

@_silgen_name("CGCursorIsVisible")
private func CGCursorIsActuallyVisible() -> Int32

enum CursorVisibility {
    private static let imageVisibilityCheckInterval: TimeInterval = 1.0 / 15.0

    private static var lastImageVisibilityCheck: TimeInterval = 0
    private static var cachedCursorHasVisiblePixels = true

    static var isVisible: Bool {
        guard CGCursorIsActuallyVisible() != 0 else {
            cachedCursorHasVisiblePixels = false
            return false
        }

        let now = CACurrentMediaTime()
        if now - lastImageVisibilityCheck >= imageVisibilityCheckInterval {
            cachedCursorHasVisiblePixels = currentCursorHasVisiblePixels
            lastImageVisibilityCheck = now
        }

        return cachedCursorHasVisiblePixels
    }

    private static var currentCursorHasVisiblePixels: Bool {
        guard let image = NSCursor.currentSystem?.image else {
            return false
        }
        return imageHasVisiblePixels(image)
    }

    private static func imageHasVisiblePixels(_ image: NSImage) -> Bool {
        var rect = NSRect(origin: .zero, size: image.size)
        guard let cgImage = image.cgImage(forProposedRect: &rect, context: nil, hints: nil) else {
            return true
        }

        let width = cgImage.width
        let height = cgImage.height
        guard width > 0, height > 0 else { return false }

        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue

        let didDraw = pixels.withUnsafeMutableBytes { buffer in
            guard let context = CGContext(
                data: buffer.baseAddress,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: width * 4,
                space: colorSpace,
                bitmapInfo: bitmapInfo
            ) else {
                return false
            }

            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }

        guard didDraw else { return true }

        var alphaIndex = 3
        while alphaIndex < pixels.count {
            if pixels[alphaIndex] > 8 {
                return true
            }
            alphaIndex += 4
        }
        return false
    }
}
