//
//  AppGroup.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 20/05/2026.
//

import Foundation
import SwiftData

enum AppGroup {
    static let identifier = "group.com.louiscarboestaque.Trente"

    static var sharedStoreURL: URL {
        guard let container = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: identifier
        ) else {
            fatalError("Shared App Group container not found: \(identifier)")
        }
        return container.appending(path: "Trente.sqlite")
    }

    static func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
        let schema = Schema([Month.self])
        if inMemory {
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            return try ModelContainer(for: schema, configurations: [config])
        }
        let config = ModelConfiguration(schema: schema, url: sharedStoreURL)
        return try ModelContainer(for: schema, configurations: [config])
    }
}
