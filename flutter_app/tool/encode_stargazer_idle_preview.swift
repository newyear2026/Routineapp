import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

// Encode the eight drawings with exactly the app's frame holds (4 s total).
// Run after export_stargazer_idle_atlas.swift and render_stargazer_idle_preview.dart.
let root = "design/stargazer-idle-8"
let delays: [Double] = [2.8, 0.18, 0.1, 0.12, 0.1, 0.1, 0.18, 0.42]

func read(_ path: String) -> CGImage {
    guard let source = CGImageSourceCreateWithURL(URL(fileURLWithPath: path) as CFURL, nil),
          let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
    else { fatalError("Cannot read \(path)") }
    return image
}

func gif(_ name: String, frames: [CGImage]) {
    let output = URL(fileURLWithPath: "\(root)/\(name).gif")
    guard let destination = CGImageDestinationCreateWithURL(output as CFURL,
        UTType.gif.identifier as CFString, frames.count, nil) else { fatalError(name) }
    CGImageDestinationSetProperties(destination, [
        kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFLoopCount: 0]
    ] as CFDictionary)
    for (index, frame) in frames.enumerated() {
        CGImageDestinationAddImage(destination, frame, [
            kCGImagePropertyGIFDictionary: [
                kCGImagePropertyGIFDelayTime: delays[index],
                kCGImagePropertyGIFUnclampedDelayTime: delays[index]
            ]
        ] as CFDictionary)
    }
    guard CGImageDestinationFinalize(destination) else { fatalError("GIF write failed") }
    print(output.path)
}

for name in ["home", "card"] {
    gif("\(name)-preview", frames: (1...8).map { read("\(root)/rendered/\(name)-\($0).png") })
}
let characterFrames = (1...8).map { index -> CGImage in
    let image = read(String(format: "%@/frames/frame-%02d.png", root, index))
    // Identical framing and background on each frame; no drawing modifications.
    let cropped = image.cropping(to: CGRect(x: 60, y: 20, width: 320, height: 354))!
    let info = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
    let ctx = CGContext(data: nil, width: 320, height: 354,
        bitsPerComponent: 8, bytesPerRow: 320 * 4,
        space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: info)!
    ctx.setFillColor(red: 1, green: 0.983, blue: 0.949, alpha: 1)
    ctx.fill(CGRect(x: 0, y: 0, width: 320, height: 354))
    ctx.interpolationQuality = .none
    ctx.draw(cropped, in: CGRect(x: 0, y: 0, width: 320, height: 354))
    return ctx.makeImage()!
}
gif("character-preview", frames: characterFrames)
