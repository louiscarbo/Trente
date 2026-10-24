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
        // .automatic syncs with the iCloud container from the entitlements, and stays local without one.
        let configuration = ModelConfiguration(schema: .trente, isStoredInMemoryOnly: false, cloudKitDatabase: .automatic)
        return Result {
            try ModelContainer(for: .trente, migrationPlan: TrenteMigrationPlan.self, configurations: [configuration])
        }
        #endif
    }()
}
