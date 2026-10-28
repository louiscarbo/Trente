//
//  ImageAttachmentLoaderTests.swift
//  TrenteTests
//
//  Created by Louis Carbo Estaque on 28/10/2026.
//

import Testing
import Foundation
@testable import Trente

@MainActor
struct ImageAttachmentLoaderTests {
    @Test("A newer photo wins over a slower older one")
    func newerPhotoWins() async {
        let loader = ImageAttachmentLoader()
        let (gate, release) = AsyncStream.makeStream(of: Void.self)
        var loadedData: [Data] = []

        loader.load({
            for await _ in gate { break }
            return Data("older".utf8)
        }) { loadedData.append($0) }
        let olderLoad = loader.currentLoad
        loader.load({ Data("newer".utf8) }) { loadedData.append($0) }
        await loader.currentLoad?.value
        release.yield()
        await olderLoad?.value

        #expect(loadedData == [Data("newer".utf8)])
        #expect(!loader.isLoading)
    }

    @Test("A failed or empty photo shows an error and delivers nothing", arguments: [true, false])
    func failedPhotoDeliversNothing(throwsError: Bool) async {
        let loader = ImageAttachmentLoader()
        var loadedData: [Data] = []

        loader.load({
            if throwsError { throw CocoaError(.fileReadUnknown) }
            return nil
        }) { loadedData.append($0) }
        await loader.currentLoad?.value

        #expect(loadedData.isEmpty)
        #expect(loader.error != nil)
        #expect(!loader.isLoading)
    }
}
