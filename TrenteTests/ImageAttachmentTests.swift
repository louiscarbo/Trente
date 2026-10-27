//
//  ImageAttachmentTests.swift
//  TrenteTests
//

import CoreGraphics
import Foundation
import ImageIO
import Testing
import UniformTypeIdentifiers
@testable import Trente

struct ImageAttachmentTests {
    private func pngData(width: Int, height: Int) -> Data {
        let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        )!
        let pixels = context.data!.bindMemory(to: UInt8.self, capacity: context.bytesPerRow * height)
        var seed: UInt32 = 42
        for offset in 0..<(context.bytesPerRow * height) {
            seed = seed &* 1_664_525 &+ 1_013_904_223
            pixels[offset] = UInt8(truncatingIfNeeded: seed >> 24)
        }
        let output = NSMutableData()
        let destination = CGImageDestinationCreateWithData(output, UTType.png.identifier as CFString, 1, nil)!
        CGImageDestinationAddImage(destination, context.makeImage()!, nil)
        CGImageDestinationFinalize(destination)
        return output as Data
    }

    private func pixelSize(of data: Data) -> (width: Int, height: Int)? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? Int,
              let height = properties[kCGImagePropertyPixelHeight] as? Int
        else { return nil }
        return (width, height)
    }

    @Test func shrinksLargePhotosToTheMaximumSize() throws {
        let original = pngData(width: 2560, height: 1920)

        let prepared = try #require(ImageAttachment.downscaled(original))
        let size = try #require(pixelSize(of: prepared))

        #expect(size.width == ImageAttachment.maximumPixelSize)
        #expect(size.height == 1536)
        #expect(prepared.count < original.count)
    }

    @Test func keepsSmallImagesAtTheirSize() throws {
        let original = pngData(width: 800, height: 600)

        let prepared = try #require(ImageAttachment.downscaled(original))
        let size = try #require(pixelSize(of: prepared))

        #expect(size.width == 800)
        #expect(size.height == 600)
        #expect(prepared.count <= original.count)
    }

    @Test func leavesUnreadableDataUntouched() async {
        let notAnImage = Data("not an image".utf8)

        #expect(ImageAttachment.downscaled(notAnImage) == nil)
        #expect(await ImageAttachment.prepared(notAnImage) == notAnImage)
    }
}
