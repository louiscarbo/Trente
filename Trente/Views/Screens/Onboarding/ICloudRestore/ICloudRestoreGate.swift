//
//  ICloudRestoreGate.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 26/10/2026.
//

import CloudKit
import Foundation

enum ICloudRestoreGate {
    enum Decision: Equatable {
        case searching
        case welcomeBack
        case onboarding
    }

    static let timeout: Duration = .seconds(20)

    static func decision(accountStatus: CKAccountStatus?, didFinishImport: Bool, monthCount: Int) -> Decision {
        guard monthCount == 0 else { return .welcomeBack }
        switch accountStatus {
        case .none, .temporarilyUnavailable:
            return .searching
        case .available:
            return didFinishImport ? .onboarding : .searching
        default:
            return .onboarding
        }
    }
}
