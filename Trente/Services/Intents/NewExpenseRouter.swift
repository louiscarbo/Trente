//
//  NewExpenseRouter.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 29/10/2026.
//

import Foundation
import Observation

@Observable
@MainActor
final class NewExpenseRouter {
    static let shared = NewExpenseRouter()

    var isRequested = false

    private init() {}
}
