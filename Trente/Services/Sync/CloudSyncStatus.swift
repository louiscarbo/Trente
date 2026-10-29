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
    case needsAttention(CloudSyncIssue)

    static func status(isSignedIn: Bool, lastSyncDate: Date?, issue: CloudSyncIssue?) -> CloudSyncStatus {
        guard isSignedIn else { return .signedOut }
        if let issue {
            return .needsAttention(issue)
        }
        if let lastSyncDate {
            return .synced(lastSyncDate)
        }
        return .waiting
    }
}
