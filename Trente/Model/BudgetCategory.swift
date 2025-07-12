//
//  BudgetCategory.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 16/04/2025.
//

import Foundation
import SwiftUI

enum BudgetCategory: String, Codable, CaseIterable {
    case needs
    case wants
    case savingsAndDebts
    
    var name: String {
        switch self {
        case .needs:
            String(localized: "Needs")
        case .wants:
            String(localized: "Wants")
        case .savingsAndDebts:
            String(localized: "Savings and Debts")
        }
    }
    
    var shortName: String {
        switch self {
        case .needs:
            String(localized: "Needs")
        case .wants:
            String(localized: "Wants")
        case .savingsAndDebts:
            String(localized: "Savings")
        }
    }
    
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
    
    var shortExamples: String {
        switch self {
        case .needs:
            String(localized: "Rent, groceries, bills...")
        case .wants:
            String(localized: "Dining out, entertainment...")
        case .savingsAndDebts:
            String(localized: "Savings, debt, retirement...")
        }
    }
}
