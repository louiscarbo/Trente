//
//  ImageAttachment.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 27/10/2026.
//

import Foundation
import ImageIO
import UniformTypeIdentifiers

enum ImageAttachment {
    static let maximumPixelSize = 2048
    static let compressionQuality = 0.8

    @concurrent
    static func prepared(_ data: Data) async -> Data {
        downscaled(data) ?? data
    }

    static func downscaled(_ data: Data, maximumPixelSize: Int = maximumPixelSize) -> Data? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        let thumbnailOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maximumPixelSize
        ]
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, thumbnailOptions as CFDictionary) else { return nil }

        let output = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(output, UTType.jpeg.identifier as CFString, 1, nil) else {
            return nil
        }
        let encodingOptions: [CFString: Any] = [kCGImageDestinationLossyCompressionQuality: compressionQuality]
        CGImageDestinationAddImage(destination, image, encodingOptions as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { return nil }

        let encoded = output as Data
        return encoded.count < data.count ? encoded : data
    }
}
