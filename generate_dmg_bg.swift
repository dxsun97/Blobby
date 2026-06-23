#!/usr/bin/env swift
import AppKit

let width: CGFloat = 500
let height: CGFloat = 340
let image = NSImage(size: NSSize(width: width, height: height))
image.lockFocus()

let ctx = NSGraphicsContext.current!.cgContext

// White background
ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))

// Arrow between icon positions
let arrowY: CGFloat = 170
let arrowStartX: CGFloat = 190
let arrowEndX: CGFloat = 310

ctx.setStrokeColor(CGColor(red: 0, green: 0, blue: 0, alpha: 0.12))
ctx.setLineWidth(1.5)
ctx.setLineCap(.round)

// Dashed line
let dashPattern: [CGFloat] = [6, 4]
ctx.setLineDash(phase: 0, lengths: dashPattern)
ctx.move(to: CGPoint(x: arrowStartX, y: arrowY))
ctx.addLine(to: CGPoint(x: arrowEndX, y: arrowY))
ctx.strokePath()

// Arrow head
ctx.setLineDash(phase: 0, lengths: [])
let headSize: CGFloat = 8
ctx.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: 0.12))
ctx.move(to: CGPoint(x: arrowEndX + headSize, y: arrowY))
ctx.addLine(to: CGPoint(x: arrowEndX, y: arrowY + headSize * 0.6))
ctx.addLine(to: CGPoint(x: arrowEndX, y: arrowY - headSize * 0.6))
ctx.closePath()
ctx.fillPath()

image.unlockFocus()

let tiffData = image.tiffRepresentation!
let bitmap = NSBitmapImageRep(data: tiffData)!
let pngData = bitmap.representation(using: .png, properties: [:])!
let outputPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "dmg_background.png"
try! pngData.write(to: URL(fileURLWithPath: outputPath))
print("Saved \(outputPath)")
