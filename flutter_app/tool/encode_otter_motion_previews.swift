import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

// Walking loops at runtime. Completion repeats here only for review.
let root = "design/otter-motion-8"
let timings: [String: [Double]] = [
    "idle": [2.8, 0.18, 0.10, 0.12, 0.10, 0.10, 0.18, 0.42],
    "walk": [0.12, 0.12, 0.12, 0.12, 0.12, 0.12, 0.12, 0.12],
    "complete": [0.1, 0.12, 0.14, 0.18, 0.14, 0.14, 0.16, 0.22]
]
func read(_ path: String) -> CGImage {
    let source = CGImageSourceCreateWithURL(URL(fileURLWithPath: path) as CFURL, nil)!
    return CGImageSourceCreateImageAtIndex(source, 0, nil)!
}
func gif(_ path: String, frames: [CGImage], delays: [Double], hold: Bool) {
    let url = URL(fileURLWithPath: path)
    let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.gif.identifier as CFString, frames.count, nil)!
    CGImageDestinationSetProperties(dest, [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFLoopCount: 0]] as CFDictionary)
    for (i, image) in frames.enumerated() {
        let duration = delays[i] + (hold && i == 7 ? 2.0 : 0)
        CGImageDestinationAddImage(dest, image, [kCGImagePropertyGIFDictionary: [
            kCGImagePropertyGIFDelayTime: duration,
            kCGImagePropertyGIFUnclampedDelayTime: duration
        ]] as CFDictionary)
    }
    guard CGImageDestinationFinalize(dest) else { fatalError(path) }
    print(path)
}
for kind in ["idle", "walk", "complete"] {
    let folder = "\(root)/\(kind)"
    for name in ["home", "card"] {
        gif("\(folder)/\(name)-preview.gif",
            frames: (1...8).map { read("\(folder)/rendered/\(name)-\($0).png") },
            delays: timings[kind]!, hold: kind == "complete")
    }
    let frames = (1...8).map { index -> CGImage in
        let frameRoot = kind == "walk" ? "design/home-walk-loop-8/otter" : folder
        let image = read(String(format: "%@/frames/frame-%02d.png", frameRoot, index))
        let info = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
        let ctx = CGContext(data: nil, width: 384, height: 384, bitsPerComponent: 8,
            bytesPerRow: 384 * 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: info)!
        ctx.interpolationQuality = .none
        ctx.setFillColor(red: 1, green: 0.983, blue: 0.949, alpha: 1)
        ctx.fill(CGRect(x: 0, y: 0, width: 384, height: 384))
        ctx.draw(image, in: CGRect(x: 0, y: 0, width: 384, height: 384))
        return ctx.makeImage()!
    }
    gif("\(folder)/character-preview.gif", frames: frames, delays: timings[kind]!, hold: kind == "complete")
}
