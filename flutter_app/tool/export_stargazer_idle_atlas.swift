import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

// Mechanical sprite-sheet export only; all eight drawings are ImageGen output.
// Run from flutter_app: swift -module-cache-path /private/tmp/loopet-swift-cache
//   tool/export_stargazer_idle_atlas.swift
let sourcePath = "design/stargazer-idle-8/source/generated-sheet.png"
let outputPath = "assets/characters/cat_stargazer/v1/motion/idle_8.png"
let framesPath = "design/stargazer-idle-8/frames"
let side = 384
let info = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue

func bitmap(_ width: Int, _ height: Int) -> CGContext {
    guard let ctx = CGContext(data: nil, width: width, height: height,
                              bitsPerComponent: 8, bytesPerRow: width * 4,
                              space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: info)
    else { fatalError("Cannot create bitmap") }
    ctx.interpolationQuality = .none
    return ctx
}

func save(_ image: CGImage, to path: String) throws {
    let url = URL(fileURLWithPath: path)
    try FileManager.default.createDirectory(at: url.deletingLastPathComponent(),
                                            withIntermediateDirectories: true)
    guard let dest = CGImageDestinationCreateWithURL(url as CFURL,
                  UTType.png.identifier as CFString, 1, nil) else { fatalError(path) }
    CGImageDestinationAddImage(dest, image, nil)
    guard CGImageDestinationFinalize(dest) else { fatalError("Cannot save \(path)") }
}

guard let source = CGImageSourceCreateWithURL(URL(fileURLWithPath: sourcePath) as CFURL, nil),
      let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
else { fatalError("Cannot read source") }

let atlas = bitmap(side * 4, side * 2)
for index in 0..<8 {
    let col = index % 4, row = index / 4
    let x = col * image.width / 4, x2 = (col + 1) * image.width / 4
    let y = row * image.height / 2, y2 = (row + 1) * image.height / 2
    guard let cell = image.cropping(to: CGRect(x: x, y: y, width: x2 - x, height: y2 - y))
    else { fatalError("Cannot extract frame \(index)") }
    let frame = bitmap(side, side)
    frame.draw(cell, in: CGRect(x: 0, y: 0, width: side, height: side))
    guard let exported = frame.makeImage() else { fatalError("Cannot render frame") }
    try save(exported, to: String(format: "%@/frame-%02d.png", framesPath, index + 1))
    atlas.draw(exported, in: CGRect(x: col * side, y: (1 - row) * side,
                                    width: side, height: side))
}
try save(atlas.makeImage()!, to: outputPath)
print("Exported 8 transparent 384×384 frames and \(outputPath)")
