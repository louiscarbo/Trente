//
//  TestSupport.swift
//  TrenteTests
//
//  Created by Louis Carbo Estaque on 08/10/2026.
//

import SwiftData
import Foundation
@testable import Trente

func makeContext() throws -> ModelContext {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(for: .trente, configurations: config)
    return ModelContext(container)
}

@discardableResult
func insertMonth(year: Int, month: Int, in context: ModelContext) -> Month {
    let eur = Currencies.currency(for: "EUR")!
    let month = Month(
        startDate: Calendar.current.date(from: DateComponents(year: year, month: month, day: 1))!,
        currency: eur,
        idealBudgetCents: 2000_00,
        idealRepartition: [.needs: 50, .wants: 30, .savingsAndDebts: 20]
    )
    context.insert(month)
    return month
}
