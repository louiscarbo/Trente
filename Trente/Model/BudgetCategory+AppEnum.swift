//
//  BudgetCategory+AppEnum.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 29/10/2026.
//

import AppIntents

extension BudgetCategory: AppEnum {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Budget Category"

    static let caseDisplayRepresentations: [BudgetCategory: DisplayRepresentation] = [
        .needs: DisplayRepresentation(title: "Needs"),
        .wants: DisplayRepresentation(title: "Wants"),
        .savingsAndDebts: DisplayRepresentation(title: "Savings and Debts", synonyms: ["Savings", "Debts"])
    ]
}
