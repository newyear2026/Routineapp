import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

// Mechanical slicing, uniform resizing and ground registration only.
// All character drawings come from ImageGen; no anatomy is redrawn by code.
let root = "design/poodle-motion-8"
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
    case "idle": ground = [419, 419, 419, 419, 419, 419, 419, 419]
    case "walk": ground = [398, 401, 401, 401, 390, 392, 390, 397]
    default: ground = [422, 420, 420, 420, 420, 389, 405, 405]
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
        } else {
            let scale = Double(side) / (Double(image.width) / 4) * 0.9
            let height = Double(cell.height) * scale
            // Keep the spring visible while the airborne paws are tucked.
            let lift = kind == "complete" ? [0.0, 0, 0, -28, -14, 0, 0, 0][index] : 0
            let top = 362.0 - ground[index] * scale + lift
            let left = (Double(side) - Double(cell.width) * scale) / 2
            frame.draw(cell, in: CGRect(x: left, y: Double(side) - top - height,
                width: Double(cell.width) * scale, height: height))
        }
        let exported = frame.makeImage()!
        try save(exported, String(format: "%@/%@/frames/frame-%02d.png", root, kind, index + 1))
        atlas.draw(exported, in: CGRect(x: col * side, y: (1 - row) * side, width: side, height: side))
    }
    let path = "assets/characters/poodle_garden/v1/motion/\(kind)_8.png"
    try save(atlas.makeImage()!, path)
    print(path)
}
