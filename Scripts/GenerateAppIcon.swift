// Run from the project root: swift Scripts/GenerateAppIcon.swift
// Exports the approved dice artwork as an opaque 1024 × 1024 iOS icon.
import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

let sourceURL = URL(fileURLWithPath: "Design/AppIcon-source.png")
let source = CGImageSourceCreateWithURL(sourceURL as CFURL, nil)!
let image = CGImageSourceCreateImageAtIndex(source, 0, nil)!
precondition(image.width == image.height, "App icon source must be square")
let size = 1024
let context = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8,
    bytesPerRow: size * 4, space: CGColorSpaceCreateDeviceRGB(),
    bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
context.setFillColor(CGColor(red: 0.035, green: 0.045, blue: 0.075, alpha: 1))
context.fill(CGRect(x: 0, y: 0, width: size, height: size))
context.interpolationQuality = .high
context.draw(image, in: CGRect(x: 0, y: 0, width: size, height: size))
let path = "DreiFragezeichen/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
let destination = CGImageDestinationCreateWithURL(URL(fileURLWithPath: path) as CFURL,
    UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(destination, context.makeImage()!, nil)
precondition(CGImageDestinationFinalize(destination))
print("Wrote \(path)")
