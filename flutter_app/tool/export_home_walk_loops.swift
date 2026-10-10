import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

// Mechanical cell slicing, uniform scaling and baseline registration only.
// Every drawing, including all eight gait phases, comes from ImageGen.
struct Registration: Decodable {
    let label: String
    let pack: String
    let scale: Double
    let centerX: Double
    let ground: [Double]
}
let root = "design/home-walk-loop-8"
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
let data = try Data(contentsOf: URL(fileURLWithPath: "\(root)/registration.json"))
let registrations = try JSONDecoder().decode([Registration].self, from: data)
for spec in registrations {
    let image = read("\(root)/\(spec.label)/source/generated-sheet.png")
    let atlas = bitmap(side * 4, side * 2)
    precondition(spec.ground.count == 8)
    for index in 0..<8 {
        let col = index % 4, row = index / 4
        let x = col * image.width / 4, x2 = (col + 1) * image.width / 4
        let y = row * image.height / 2, y2 = (row + 1) * image.height / 2
        let cell = image.cropping(to: CGRect(x: x, y: y, width: x2 - x, height: y2 - y))!
        let frame = bitmap(side, side)
        let height = Double(cell.height) * spec.scale
        let top = 362.0 - spec.ground[index] * spec.scale
        let left = Double(side) / 2 - spec.centerX * spec.scale
        // Do not substitute idle/standing endpoints. Frame 8 joins frame 1 mid-stride.
        frame.draw(cell, in: CGRect(x: left, y: Double(side) - top - height,
            width: Double(cell.width) * spec.scale, height: height))
        let exported = frame.makeImage()!
        try save(exported, String(format: "%@/%@/frames/frame-%02d.png", root, spec.label, index + 1))
        atlas.draw(exported, in: CGRect(x: col * side, y: (1 - row) * side, width: side, height: side))
    }
    let path = "assets/characters/\(spec.pack)/v1/motion/walk_loop_8.png"
    try save(atlas.makeImage()!, path)
    print(path)
}
