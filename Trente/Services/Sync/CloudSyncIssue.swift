//
//  CloudSyncIssue.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 26/10/2026.
//

import CloudKit
import Foundation

enum CloudSyncIssue: Equatable {
    case storageFull
    case accountUnavailable

    init?(error: any Error) {
        guard let cloudKitError = error as? CKError else { return nil }
        switch cloudKitError.code {
        case .quotaExceeded:
            self = .storageFull
        case .notAuthenticated, .managedAccountRestricted:
            self = .accountUnavailable
        case .partialFailure:
            let itemErrors = cloudKitError.partialErrorsByItemID?.values.map { $0 } ?? []
            guard let issue = itemErrors.lazy.compactMap(CloudSyncIssue.init(error:)).first else { return nil }
            self = issue
        default:
            return nil
        }
    }
}
