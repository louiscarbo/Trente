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

    static var usesICloudStore: Bool {
        #if DEBUG
        ProcessInfo.processInfo.arguments.contains(iCloudStoreArgument)
        #else
        true
        #endif
    }

    static let shared: Result<ModelContainer, any Error> = {
        guard usesICloudStore else {
            #if DEBUG
            if StoreCapture.isEnabled {
                return Result { try StoreCapture.makeModelContainer() }
            }
            #endif
            return .success(DataProvider.shared.modelContainer)
        }
        let configuration = ModelConfiguration(schema: .trente, isStoredInMemoryOnly: false, cloudKitDatabase: .automatic)
        return Result {
            try ModelContainer(for: .trente, migrationPlan: TrenteMigrationPlan.self, configurations: [configuration])
        }
    }()
}
