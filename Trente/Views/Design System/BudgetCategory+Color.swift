//
//  BudgetCategory+Color.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 28/10/2026.
//

import SwiftUI

extension BudgetCategory {
    var color: Color {
        switch self {
        case .needs:
            Color.blue
        case .wants:
            Color.yellow
        case .savingsAndDebts:
            Color.green
        }
    }
}
