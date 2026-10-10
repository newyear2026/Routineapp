import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

// Export transparent imagegen source PNGs at the app's 384 px asset size.
// CoreGraphics uses nearest-neighbor sampling to preserve hard pixel edges.
guard CommandLine.arguments.count == 3 else {
    fputs("usage: swift export_stargazer_assets.swift INPUT.png OUTPUT.png\n", stderr)
    exit(2)
}

let inputURL = URL(fileURLWithPath: CommandLine.arguments[1])
let outputURL = URL(fileURLWithPath: CommandLine.arguments[2])
guard let source = CGImageSourceCreateWithURL(inputURL as CFURL, nil),
      let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
    fatalError("Cannot read \(inputURL.path)")
}

let side = 384
let bytesPerRow = side * 4
let info = CGImageAlphaInfo.premultipliedLast.rawValue |
    CGBitmapInfo.byteOrder32Big.rawValue
guard let context = CGContext(
    data: nil,
    width: side,
    height: side,
    bitsPerComponent: 8,
    bytesPerRow: bytesPerRow,
    space: CGColorSpaceCreateDeviceRGB(),
    bitmapInfo: info
) else { fatalError("Cannot create bitmap context") }
context.interpolationQuality = .none
context.draw(image, in: CGRect(x: 0, y: 0, width: side, height: side))

guard let bytes = context.data,
      let exported = context.makeImage() else {
    fatalError("Cannot render \(inputURL.path)")
}
var minX = side, minY = side, maxX = -1, maxY = -1
let pixels = bytes.bindMemory(to: UInt8.self, capacity: side * bytesPerRow)
for y in 0..<side {
    for x in 0..<side where pixels[y * bytesPerRow + x * 4 + 3] > 8 {
        minX = min(minX, x)
        minY = min(minY, y)
        maxX = max(maxX, x)
        maxY = max(maxY, y)
    }
}
guard maxX >= minX, maxY >= minY else { fatalError("Empty alpha in \(inputURL.path)") }

try FileManager.default.createDirectory(
    at: outputURL.deletingLastPathComponent(),
    withIntermediateDirectories: true
)
guard let destination = CGImageDestinationCreateWithURL(
    outputURL as CFURL, UTType.png.identifier as CFString, 1, nil
) else { fatalError("Cannot write \(outputURL.path)") }
CGImageDestinationAddImage(destination, exported, nil)
guard CGImageDestinationFinalize(destination) else { fatalError("PNG write failed") }
print("\(outputURL.lastPathComponent) \(minX) \(minY) \(maxX + 1) \(maxY + 1)")
