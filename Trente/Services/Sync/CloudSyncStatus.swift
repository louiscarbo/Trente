//
//  CloudSyncStatus.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 24/10/2026.
//

import Foundation

enum CloudSyncStatus: Equatable {
    case signedOut
    case waiting
    case synced(Date)
    case failed(String)

    static func status(isSignedIn: Bool, lastSyncDate: Date?, lastErrorDescription: String?) -> CloudSyncStatus {
        guard isSignedIn else { return .signedOut }
        if let lastErrorDescription {
            return .failed(lastErrorDescription)
        }
        if let lastSyncDate {
            return .synced(lastSyncDate)
        }
        return .waiting
    }
}
