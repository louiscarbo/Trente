//
//  ImageAttachmentLoader.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 28/10/2026.
//

import Foundation

@MainActor
@Observable
final class ImageAttachmentLoader {
    private(set) var isLoading = false
    var error: String?

    @ObservationIgnored private(set) var currentLoad: Task<Void, Never>?

    func load(_ loadData: @escaping @Sendable () async throws -> Data?, onLoaded: @escaping (Data) -> Void) {
        currentLoad?.cancel()
        isLoading = true
        currentLoad = Task {
            var preparedData: Data?
            if let loadedData = try? await loadData() {
                preparedData = await ImageAttachment.prepared(loadedData)
            }
            guard !Task.isCancelled else { return }
            if let preparedData {
                onLoaded(preparedData)
            } else {
                error = String(localized: "The image could not be loaded. Please try again.")
            }
            isLoading = false
        }
    }
}
