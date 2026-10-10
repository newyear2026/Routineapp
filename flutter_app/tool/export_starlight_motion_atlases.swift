import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

// Mechanical slicing, uniform resizing and ground registration only.
// All character drawings, including the anatomy repair, come from ImageGen.
let root = "design/starlight-motion-8"
let side = 384
let info = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
func bitmap(_ width: Int, _ height: Int) -> CGContext {
    let ctx = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8,
        bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: info)!
    ctx.interpolationQuality = .none
    return ctx
}
func read(_ path: String) -> CGImage {
    let source = CGImageSourceCreateWithURL(URL(fileURLWithPath: path) as CFURL, nil)!
    return CGImageSourceCreateImageAtIndex(source, 0, nil)!
}
func save(_ image: CGImage, _ path: String) throws {
    let url = URL(fileURLWithPath: path)
    try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, image, nil)
    guard CGImageDestinationFinalize(dest) else { fatalError(path) }
}

for kind in ["idle", "walk", "complete"] {
    let image = read("\(root)/\(kind)/source/generated-sheet.png")
    let atlas = bitmap(side * 4, side * 2)
    // Each value is the source ground plane, not the sprite's top/bottom box.
    // Frames 4–5 of completion retain their airborne height above that plane.
    let ground: [Double]
    switch kind {
    case "idle": ground = [425, 425, 425, 425, 426, 426, 426, 426]
    case "walk": ground = [412, 413, 416, 414, 391, 388, 396, 409]
    default: ground = [419, 421, 421, 421, 419, 397, 419, 419]
    }
    for index in 0..<8 {
        let col = index % 4, row = index / 4
        let x = col * image.width / 4, x2 = (col + 1) * image.width / 4
        let y = row * image.height / 2, y2 = (row + 1) * image.height / 2
        let cell = image.cropping(to: CGRect(x: x, y: y, width: x2 - x, height: y2 - y))!
        let frame = bitmap(side, side)
        if (kind != "idle" && index == 0) || ((kind == "walk" || kind == "idle") && index == 7) {
            let neutral = read("\(root)/idle/frames/frame-01.png")
            frame.draw(neutral, in: CGRect(x: 0, y: 0, width: side, height: side))
        } else if kind == "complete" && index == 6 {
            // Corrected drawing has only two raised front paws and two hind feet.
            // Preserve the rejected frame's 77,74..402,419 source footprint.
            let repaired = read("\(root)/complete/source/repaired-frame-07.png")
            let sheetScale = Double(side) / (Double(image.width) / 4)
            let scale = 345.0 * sheetScale / 956.0
            let left = 77.0 * sheetScale - 212.0 * scale
            let top = 362.0 - 1160.0 * scale
            let height = Double(repaired.height) * scale
            frame.draw(repaired, in: CGRect(x: left, y: Double(side) - top - height,
                width: Double(repaired.width) * scale, height: height))
        } else {
            let scale = Double(side) / (Double(image.width) / 4)
            let height = Double(cell.height) * scale
            let top = 362.0 - ground[index] * scale
            frame.draw(cell, in: CGRect(x: 0, y: Double(side) - top - height,
                width: Double(cell.width) * scale, height: height))
        }
        let exported = frame.makeImage()!
        try save(exported, String(format: "%@/%@/frames/frame-%02d.png", root, kind, index + 1))
        atlas.draw(exported, in: CGRect(x: col * side, y: (1 - row) * side, width: side, height: side))
    }
    let path = "assets/characters/cat_starlight/v1/motion/\(kind)_8.png"
    try save(atlas.makeImage()!, path)
    print(path)
}
