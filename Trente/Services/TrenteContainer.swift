//
//  TrenteContainer.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 07/10/2026.
//

import SwiftData

@MainActor
enum TrenteContainer {
    static let shared: ModelContainer = {
        #if DEBUG
        return DataProvider.shared.modelContainer
        #else
        let configuration = ModelConfiguration(schema: .trente, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: .trente, configurations: [configuration])
        } catch {
            // TODO: Maybe fail more gracefully?
            fatalError("Failed to initialize ModelContainer: \(error)")
        }
        #endif
    }()
}
