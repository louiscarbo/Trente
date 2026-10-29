import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data((message + "\n").utf8))
    exit(1)
}

func loadImage(at path: String) -> CGImage {
    guard
        let source = CGImageSourceCreateWithURL(URL(fileURLWithPath: path) as CFURL, nil),
        let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
    else { fail("Cannot read \(path)") }
    return image
}

func makeContext(for image: CGImage) -> CGContext {
    guard let context = CGContext(
        data: nil,
        width: image.width,
        height: image.height,
        bitsPerComponent: 8,
        bytesPerRow: image.width * 4,
        space: CGColorSpace(name: CGColorSpace.sRGB)!,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else { fail("Cannot create bitmap context") }
    context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
    return context
}

func rgb(in context: CGContext, x: Int, topY: Int) -> Int {
    let bytes = context.data!.assumingMemoryBound(to: UInt8.self)
    let offset = topY * context.bytesPerRow + x * 4
    return Int(bytes[offset]) << 16 | Int(bytes[offset + 1]) << 8 | Int(bytes[offset + 2])
}

func save(_ context: CGContext, to path: String) {
    guard
        let image = context.makeImage(),
        let destination = CGImageDestinationCreateWithURL(URL(fileURLWithPath: path) as CFURL, UTType.png.identifier as CFString, 1, nil)
    else { fail("Cannot write \(path)") }
    CGImageDestinationAddImage(destination, image, nil)
    CGImageDestinationFinalize(destination)
}

func paintGrabber(at path: String) {
    let image = loadImage(at: path)
    let context = makeContext(for: image)
    let background = rgb(in: context, x: 1990, topY: 2750)
    context.setFillColor(
        red: CGFloat(background >> 16 & 0xFF) / 255,
        green: CGFloat(background >> 8 & 0xFF) / 255,
        blue: CGFloat(background & 0xFF) / 255,
        alpha: 1
    )
    let topRects = [
        CGRect(x: 2035, y: 2688, width: image.width - 2035, height: 2752 - 2688),
        CGRect(x: 2000, y: 2722, width: image.width - 2000, height: image.height - 2722)
    ]
    for rect in topRects {
        context.fill(CGRect(x: rect.minX, y: CGFloat(image.height) - rect.maxY, width: rect.width, height: rect.height))
    }
    save(context, to: path)
}

func distinctColorCount(at path: String) -> Int {
    let image = loadImage(at: path)
    let context = makeContext(for: image)
    var colors = Set<Int>()
    for column in 0..<24 {
        for row in 0..<24 {
            colors.insert(rgb(in: context, x: image.width * column / 24, topY: image.height * row / 24))
        }
    }
    return colors.count
}

func windowID(pid: Int32, width: Double, height: Double) -> Int {
    let windows = CGWindowListCopyWindowInfo(.optionAll, kCGNullWindowID) as? [[String: Any]] ?? []
    let candidates = windows.filter {
        ($0[kCGWindowOwnerPID as String] as? Int32) == pid && ($0[kCGWindowLayer as String] as? Int) == 0
    }
    func size(of window: [String: Any]) -> CGSize {
        let bounds = window[kCGWindowBounds as String] as? [String: Double] ?? [:]
        return CGSize(width: bounds["Width"] ?? 0, height: bounds["Height"] ?? 0)
    }
    guard
        let match = candidates.first(where: { size(of: $0) == CGSize(width: width, height: height) }),
        let number = match[kCGWindowNumber as String] as? Int
    else { fail("No \(Int(width))×\(Int(height)) window for pid \(pid)") }
    return number
}

let arguments = Array(CommandLine.arguments.dropFirst())
switch arguments.first {
case "paint-grabber" where arguments.count == 2:
    paintGrabber(at: arguments[1])
case "distinct-colors" where arguments.count == 2:
    print(distinctColorCount(at: arguments[1]))
case "window-id" where arguments.count == 4:
    guard let pid = Int32(arguments[1]), let width = Double(arguments[2]), let height = Double(arguments[3]) else {
        fail("window-id <pid> <width> <height>")
    }
    print(windowID(pid: pid, width: width, height: height))
default:
    fail("Usage: paint-grabber <png> | distinct-colors <png> | window-id <pid> <width> <height>")
}
