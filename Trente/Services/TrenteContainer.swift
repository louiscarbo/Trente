//
//  TrenteContainer.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 07/10/2026.
//

import Foundation
import SwiftData

@MainActor
enum TrenteContainer {
    static let iCloudStoreArgument = "-useICloudStore"

    static let shared: Result<ModelContainer, any Error> = {
        #if DEBUG
        guard ProcessInfo.processInfo.arguments.contains(iCloudStoreArgument) else {
            return .success(DataProvider.shared.modelContainer)
        }
        #endif
        let configuration = ModelConfiguration(schema: .trente, isStoredInMemoryOnly: false, cloudKitDatabase: .automatic)
        return Result {
            try ModelContainer(for: .trente, migrationPlan: TrenteMigrationPlan.self, configurations: [configuration])
        }
    }()
}
