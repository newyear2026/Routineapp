import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

// Mechanical slicing, uniform resizing and ground registration only.
// All character drawings come from ImageGen; no anatomy is redrawn by code.
let root = "design/otter-motion-8"
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
    // Otter completion keeps both seated hind feet grounded.
    let ground: [Double]
    switch kind {
    case "idle": ground = [438, 438, 438, 438, 434, 434, 434, 434]
    case "walk": ground = [411, 411, 416, 417, 403, 403, 403, 412]
    default: ground = [426, 428, 430, 430, 427, 427, 427, 427]
    }
    // Normalize each whole clip using its neutral source drawing.
    // All eight drawings in a clip share one scale; never fit individual frames.
    let clipScale: [String: Double] = ["idle": 0.9, "walk": 0.965625, "complete": 0.9]
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
            let scale = Double(side) / (Double(image.width) / 4) * clipScale[kind]!
            let height = Double(cell.height) * scale
            let top = 362.0 - ground[index] * scale
            let left = (Double(side) - Double(cell.width) * scale) / 2
            frame.draw(cell, in: CGRect(x: left, y: Double(side) - top - height,
                width: Double(cell.width) * scale, height: height))
        }
        let exported = frame.makeImage()!
        try save(exported, String(format: "%@/%@/frames/frame-%02d.png", root, kind, index + 1))
        atlas.draw(exported, in: CGRect(x: col * side, y: (1 - row) * side, width: side, height: side))
    }
    let path = "assets/characters/otter_seaside/v1/motion/\(kind)_8.png"
    try save(atlas.makeImage()!, path)
    print(path)
}
