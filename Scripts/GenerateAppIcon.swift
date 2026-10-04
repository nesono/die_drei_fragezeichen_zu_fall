// Run from the project root: swift Scripts/GenerateAppIcon.swift
// Draws the same three-mark motif as the SwiftUI screen; no external artwork.
import AppKit
import ImageIO
import UniformTypeIdentifiers

let size = 1024
let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size,
    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
    colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
NSColor(srgbRed: 0.035, green: 0.045, blue: 0.075, alpha: 1).setFill()
NSRect(x: 0, y: 0, width: size, height: size).fill()
let base = NSFont.systemFont(ofSize: 540, weight: .black)
let font = NSFont(descriptor: base.fontDescriptor.withDesign(.rounded)!, size: 540)!
let colors: [NSColor] = [.white,
    NSColor(srgbRed: 0.98, green: 0.22, blue: 0.27, alpha: 1),
    NSColor(srgbRed: 0.12, green: 0.51, blue: 1, alpha: 1)]
let mark = "?" as NSString
let width = mark.size(withAttributes: [.font: font]).width
let gap: CGFloat = 8
let start = (1024 - width * 3 - gap * 2) / 2
for (index, color) in colors.enumerated() {
    mark.draw(at: NSPoint(x: start + CGFloat(index) * (width + gap), y: 212),
              withAttributes: [.font: font, .foregroundColor: color])
}
NSGraphicsContext.restoreGraphicsState()
let path = "DreiFragezeichen/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
let opaque = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8,
    bytesPerRow: size * 4, space: CGColorSpaceCreateDeviceRGB(),
    bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
opaque.draw(bitmap.cgImage!, in: CGRect(x: 0, y: 0, width: size, height: size))
let destination = CGImageDestinationCreateWithURL(URL(fileURLWithPath: path) as CFURL,
    UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(destination, opaque.makeImage()!, nil)
precondition(CGImageDestinationFinalize(destination))
print("Wrote \(path)")
