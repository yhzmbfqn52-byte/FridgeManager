#!/usr/bin/env swift
import Foundation
import CoreGraphics
import ImageIO

let fileMap: [String: Int] = [
    "AppIcon-20.png": 20,
    "AppIcon-20@2x.png": 40,
    "AppIcon-20@3x.png": 60,
    "AppIcon-29@2x.png": 58,
    "AppIcon-29@3x.png": 87,
    "AppIcon-40@2x.png": 80,
    "AppIcon-40@3x.png": 120,
    "AppIcon-60@2x.png": 120,
    "AppIcon-60@3x.png": 180,
    "AppIcon-76@1x.png": 76,
    "AppIcon-76@2x.png": 152,
    "AppIcon-83.5@2x.png": 167,
    "AppIcon-1024.png": 1024,
    "AppLogo-1x.png": 512
]

let repoRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("..").appendingPathComponent("FridgeManager")
let assetsBase = repoRoot.appendingPathComponent("FridgeManager/Assets.xcassets")
let outDir = assetsBase.appendingPathComponent("AppIcon.appiconset")
let logoDir = assetsBase.appendingPathComponent("AppLogo.imageset")

func ensureDir(_ url: URL) {
    if !FileManager.default.fileExists(atPath: url.path) {
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }
}

ensureDir(outDir)
ensureDir(logoDir)

func writePNG(cgImage: CGImage, to url: URL) -> Bool {
    guard let dest = CGImageDestinationCreateWithURL(url as CFURL, kUTTypePNG, 1, nil) else { return false }
    CGImageDestinationAddImage(dest, cgImage, nil)
    return CGImageDestinationFinalize(dest)
}

func drawFridgeCG(size: Int) -> CGImage? {
    let width = size
    let height = size
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bitmapInfo = CGBitmapInfo.byteOrder32Big.union(CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue))

    guard let ctx = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: bitmapInfo.rawValue) else {
        return nil
    }

    // Flip coordinate system to have origin at top-left like UIKit
    ctx.translateBy(x: 0, y: CGFloat(height))
    ctx.scaleBy(x: 1.0, y: -1.0)

    ctx.clear(CGRect(x: 0, y: 0, width: width, height: height))

    let inset = CGFloat(min(width, height)) * 0.08
    let bodyRect = CGRect(x: inset, y: inset, width: CGFloat(width) - inset * 2, height: CGFloat(height) - inset * 2)
    let corner = min(bodyRect.width, bodyRect.height) * 0.12

    // Body gradient
    let topCol = CGColor(red: 0.12, green: 0.56, blue: 0.77, alpha: 1.0)
    let bottomCol = CGColor(red: 0.06, green: 0.35, blue: 0.5, alpha: 1.0)
    if let grad = CGGradient(colorsSpace: colorSpace, colors: [topCol, bottomCol] as CFArray, locations: [0,1]) {
        ctx.saveGState()
        let path = CGPath(roundedRect: bodyRect, cornerWidth: corner, cornerHeight: corner, transform: nil)
        ctx.addPath(path)
        ctx.clip()
        ctx.drawLinearGradient(grad, start: CGPoint(x: bodyRect.midX, y: bodyRect.minY), end: CGPoint(x: bodyRect.midX, y: bodyRect.maxY), options: [])
        ctx.restoreGState()

        // stroke
        ctx.addPath(path)
        ctx.setStrokeColor(CGColor(gray: 1.0, alpha: 0.08))
        ctx.setLineWidth(max(1, CGFloat(width) * 0.02))
        ctx.strokePath()
    }

    // Freezer compartment
    let freezerHeight = bodyRect.height * 0.36
    let freezerRect = CGRect(x: bodyRect.minX + bodyRect.width * 0.08, y: bodyRect.maxY - freezerHeight - bodyRect.height * 0.06, width: bodyRect.width * 0.84, height: freezerHeight)
    let freezerCorner = corner * 0.7
    ctx.setFillColor(CGColor(gray: 0.06, alpha: 1.0))
    let freezerPath = CGPath(roundedRect: freezerRect, cornerWidth: freezerCorner, cornerHeight: freezerCorner, transform: nil)
    ctx.addPath(freezerPath)
    ctx.fillPath()

    // Door line
    let doorY = bodyRect.minY + bodyRect.height * 0.12
    ctx.setStrokeColor(CGColor(gray: 0.0, alpha: 0.15))
    ctx.setLineWidth(max(1, CGFloat(width) * 0.01))
    ctx.move(to: CGPoint(x: bodyRect.minX + bodyRect.width * 0.06, y: doorY))
    ctx.addLine(to: CGPoint(x: bodyRect.maxX - bodyRect.width * 0.06, y: doorY))
    ctx.strokePath()

    // Handle
    let handleW = bodyRect.width * 0.12
    let handleH = max(4, bodyRect.height * 0.18)
    let handleRect = CGRect(x: bodyRect.maxX - handleW - bodyRect.width * 0.06, y: bodyRect.midY - handleH/2, width: handleW, height: handleH)
    let handlePath = CGPath(roundedRect: handleRect, cornerWidth: handleH/2, cornerHeight: handleH/2, transform: nil)
    ctx.setFillColor(CGColor(gray: 1.0, alpha: 0.08))
    ctx.addPath(handlePath)
    ctx.fillPath()

    // Shine
    let shineRect = CGRect(x: bodyRect.minX + bodyRect.width * 0.06, y: bodyRect.minY + bodyRect.height * 0.6, width: bodyRect.width * 0.24, height: bodyRect.height * 0.18)
    ctx.setFillColor(CGColor(gray: 1.0, alpha: 0.03))
    ctx.addEllipse(in: shineRect)
    ctx.fillPath()

    return ctx.makeImage()
}

for (name, px) in fileMap {
    let targetURL: URL
    if name.hasPrefix("AppLogo") {
        targetURL = logoDir.appendingPathComponent(name)
    } else {
        targetURL = outDir.appendingPathComponent(name)
    }

    if let img = drawFridgeCG(size: px) {
        if writePNG(cgImage: img, to: targetURL) {
            print("Wrote \(targetURL.path)")
        } else {
            print("Failed to write \(targetURL.path)")
        }
    } else {
        print("Failed to create image for \(name)")
    }
}

print("Done generating icons")
