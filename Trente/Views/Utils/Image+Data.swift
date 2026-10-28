//
//  Image+Data.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 28/10/2026.
//

import SwiftUI

extension Image {
    init?(data: Data) {
        #if canImport(UIKit)
        guard let uiImage = UIImage(data: data) else { return nil }
        self.init(uiImage: uiImage)
        #elseif canImport(AppKit)
        guard let nsImage = NSImage(data: data) else { return nil }
        self.init(nsImage: nsImage)
        #else
        return nil
        #endif
    }
}

extension Data {
    init?(assetNamed name: String) {
        #if canImport(UIKit)
        guard let data = UIImage(named: name)?.pngData() else { return nil }
        self = data
        #elseif canImport(AppKit)
        guard let data = NSImage(named: name)?.pngData() else { return nil }
        self = data
        #else
        return nil
        #endif
    }
}

#if canImport(AppKit)
extension NSImage {
    func pngData() -> Data? {
        guard let tiffData = tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else { return nil }
        return bitmap.representation(using: .png, properties: [:])
    }
}
#endif
