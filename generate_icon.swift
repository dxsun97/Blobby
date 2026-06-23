#!/usr/bin/env swift
import AppKit

let size: CGFloat = 1024
let image = NSImage(size: NSSize(width: size, height: size))
image.lockFocus()

let ctx = NSGraphicsContext.current!.cgContext

// Background: macOS-style rounded rect with gradient
let bgRect = CGRect(x: 0, y: 0, width: size, height: size)
let bgRadius: CGFloat = size * 0.22
let bgPath = CGPath(roundedRect: bgRect, cornerWidth: bgRadius, cornerHeight: bgRadius, transform: nil)

// Dark gradient background
let bgColors = [
    CGColor(red: 0.08, green: 0.08, blue: 0.14, alpha: 1.0),
    CGColor(red: 0.12, green: 0.10, blue: 0.22, alpha: 1.0),
]
ctx.saveGState()
ctx.addPath(bgPath)
ctx.clip()
let bgGradient = CGGradient(
    colorsSpace: CGColorSpaceCreateDeviceRGB(),
    colors: bgColors as CFArray,
    locations: [0.0, 1.0]
)!
ctx.drawLinearGradient(bgGradient, start: CGPoint(x: 0, y: size), end: CGPoint(x: size, y: 0), options: [])
ctx.restoreGState()

// Comet blob shape — centered, with tail pointing right
let cx = size * 0.42
let cy = size * 0.5
let r = size * 0.22
let tailX = cx + r * 2.2
let topY = cy + r * 0.9
let bottomY = cy - r * 0.9

let blobPath = CGMutablePath()
blobPath.move(to: CGPoint(x: cx - r, y: cy))

blobPath.addCurve(
    to: CGPoint(x: cx, y: topY),
    control1: CGPoint(x: cx - r, y: cy + r * 0.55),
    control2: CGPoint(x: cx - r * 0.55, y: topY)
)
blobPath.addCurve(
    to: CGPoint(x: tailX, y: cy),
    control1: CGPoint(x: cx + r * 0.6, y: topY),
    control2: CGPoint(x: tailX, y: cy + r * 0.12)
)
blobPath.addCurve(
    to: CGPoint(x: cx, y: bottomY),
    control1: CGPoint(x: tailX, y: cy - r * 0.12),
    control2: CGPoint(x: cx + r * 0.6, y: bottomY)
)
blobPath.addCurve(
    to: CGPoint(x: cx - r, y: cy),
    control1: CGPoint(x: cx - r * 0.55, y: bottomY),
    control2: CGPoint(x: cx - r, y: cy - r * 0.55)
)
blobPath.closeSubpath()

// Blob gradient fill — blue to purple
ctx.saveGState()
ctx.addPath(blobPath)
ctx.clip()
let blobColors = [
    CGColor(red: 0.35, green: 0.55, blue: 1.0, alpha: 1.0),
    CGColor(red: 0.65, green: 0.35, blue: 1.0, alpha: 1.0),
]
let blobGradient = CGGradient(
    colorsSpace: CGColorSpaceCreateDeviceRGB(),
    colors: blobColors as CFArray,
    locations: [0.0, 1.0]
)!
ctx.drawLinearGradient(blobGradient, start: CGPoint(x: cx - r, y: cy + r), end: CGPoint(x: tailX, y: cy - r), options: [])
ctx.restoreGState()

// Subtle glow behind blob
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: 0), blur: size * 0.08, color: CGColor(red: 0.4, green: 0.5, blue: 1.0, alpha: 0.4))
ctx.addPath(blobPath)
ctx.setFillColor(CGColor(red: 0.4, green: 0.5, blue: 1.0, alpha: 0.3))
ctx.fillPath()
ctx.restoreGState()

// Dot cursor — small white circle near front of blob
let dotR: CGFloat = size * 0.035
let dotX = cx - r * 0.35
let dotRect = CGRect(x: dotX - dotR, y: cy - dotR, width: dotR * 2, height: dotR * 2)
ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.95))
ctx.fillEllipse(in: dotRect)

image.unlockFocus()

// Save to Assets
let tiffData = image.tiffRepresentation!
let bitmap = NSBitmapImageRep(data: tiffData)!
let pngData = bitmap.representation(using: .png, properties: [:])!

let outputPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "AppIcon.png"
try! pngData.write(to: URL(fileURLWithPath: outputPath))
print("Saved \(outputPath) (\(pngData.count / 1024)KB)")
