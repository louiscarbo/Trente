//
//  TrenteContainer.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 07/10/2026.
//

import SwiftData

@MainActor
enum TrenteContainer {
    static let shared: Result<ModelContainer, any Error> = {
        #if DEBUG
        return .success(DataProvider.shared.modelContainer)
        #else
        let configuration = ModelConfiguration(schema: .trente, isStoredInMemoryOnly: false)
        return Result {
            try ModelContainer(for: .trente, migrationPlan: TrenteMigrationPlan.self, configurations: [configuration])
        }
        #endif
    }()
}
