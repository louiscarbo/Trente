//
//  PendingTransactionRouter.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 07/10/2026.
//

import Foundation
import Observation

@Observable
@MainActor
final class PendingTransactionRouter {
    static let shared = PendingTransactionRouter()

    var presentedPendingTransactionID: UUID?

    private init() {}
}
