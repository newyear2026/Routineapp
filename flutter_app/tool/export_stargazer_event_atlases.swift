import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

// Slice ImageGen's 4x2 sheets; register ground lines without redrawing the art.
// Ground offsets are measured from the generated feet, never from jump/effect bounds.
let root = "design/stargazer-events-8"
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
let neutral = read("design/stargazer-idle-8/frames/frame-01.png")
for kind in ["walk", "complete"] {
    let image = read("\(root)/\(kind)/source/generated-sheet.png")
    let atlas = bitmap(side * 4, side * 2)
    // Walk stays grounded; complete keeps the ascent/descent between grounded frames.
    let ground: [Double] = kind == "walk"
        ? [427, 428, 428, 428, 395, 402, 417, 418]
        : [423, 426, 423, 423, 411, 411, 411, 411]
    for index in 0..<8 {
        let col = index % 4, row = index / 4
        let x = col * image.width / 4, x2 = (col + 1) * image.width / 4
        let y = row * image.height / 2, y2 = (row + 1) * image.height / 2
        let cell = image.cropping(to: CGRect(x: x, y: y, width: x2 - x, height: y2 - y))!
        let frame = bitmap(side, side)
        if index == 0 || (kind == "walk" && index == 7) {
            // Exact neutral endpoints avoid a pop when switching to the idle atlas.
            frame.draw(neutral, in: CGRect(x: 0, y: 0, width: side, height: side))
        } else if kind == "complete" && index == 5 {
            // The original landing drawing had two extra little feet. Use
            // ImageGen's corrected four-limb drawing, registered to the old
            // 66,71..349,362 pose area. Other seven drawings stay unchanged.
            let repaired = read("\(root)/complete/source/repaired-frame-06.png")
            let scale = 291.0 / 962.0
            let left = 66.0 - 217.0 * scale
            let top = 71.0 - 182.0 * scale
            let width = Double(repaired.width) * scale
            let height = Double(repaired.height) * scale
            frame.draw(repaired, in: CGRect(x: left,
                y: Double(side) - top - height, width: width, height: height))
        } else {
            let scale = Double(side) / Double(cell.width)
            let height = Double(cell.height) * scale
            let top = 362.0 - ground[index] * scale
            frame.draw(cell, in: CGRect(x: 0, y: Double(side) - top - height,
                                       width: Double(side), height: height))
        }
        let exported = frame.makeImage()!
        try save(exported, String(format: "%@/%@/frames/frame-%02d.png", root, kind, index + 1))
        atlas.draw(exported, in: CGRect(x: col * side, y: (1 - row) * side, width: side, height: side))
    }
    let path = "assets/characters/cat_stargazer/v1/motion/\(kind)_8.png"
    try save(atlas.makeImage()!, path)
    print(path)
}
