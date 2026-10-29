//
//  BudgetScope+Display.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 28/10/2026.
//

import SwiftUI

extension BudgetScope {
    var name: String {
        switch self {
        case .all: String(localized: "Total")
        case .category(let category): category.name
        }
    }
    
    var shortName: String {
        switch self {
        case .all: String(localized: "Total")
        case .category(let category): category.shortName
        }
    }
    
    var color: Color {
        switch self {
        case .all: .purple
        case .category(let category): category.color
        }
    }
}
