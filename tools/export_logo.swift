// A simple macOS helper script to render `AppLogoView` and write PNGs at requested sizes.
// Usage: swift tools/export_logo.swift 512 output.png

import AppKit
import SwiftUI

@main
struct ExportLogo {
    static func main() throws {
        let args = CommandLine.arguments
        guard args.count >= 3 else {
            print("Usage: swift tools/export_logo.swift <size> <outputPath>")
            return
        }

        guard let size = Int(args[1]) else {
            print("Invalid size: \(args[1])")
            return
        }

        let output = args[2]

        let view = AppLogoView()
        let hosting = NSHostingView(rootView: view.frame(width: CGFloat(size), height: CGFloat(size)))
        hosting.frame = NSRect(x: 0, y: 0, width: size, height: size)

        let bitmapRep = hosting.bitmapImageRepForCachingDisplay(in: hosting.bounds)!
        hosting.cacheDisplay(in: hosting.bounds, to: bitmapRep)

        let image = NSImage(size: NSSize(width: size, height: size))
        image.addRepresentation(bitmapRep)

        guard let tiff = image.tiffRepresentation, let bitmap = NSBitmapImageRep(data: tiff),
              let data = bitmap.representation(using: .png, properties: [:]) else {
            print("Failed to rasterize image")
            return
        }

        try data.write(to: URL(fileURLWithPath: output))
        print("Wrote \(output)")
    }
}
