//
//  PaywallRouter.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 29/10/2026.
//

import Foundation
import Observation

@Observable
@MainActor
final class PaywallRouter {
    static let shared = PaywallRouter()

    var isPresentingPaywall = false

    private init() {}
}
