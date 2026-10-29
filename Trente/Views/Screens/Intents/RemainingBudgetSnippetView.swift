//
//  RemainingBudgetSnippetView.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 29/10/2026.
//

import SwiftUI

struct RemainingBudgetSnippetView: View {
    let figures: BudgetFigures
    let scope: BudgetScope
    let currencyCode: String
    let monthName: String

    var body: some View {
        HStack(spacing: 16) {
            BudgetGaugeView(
                figures: figures,
                scope: scope,
                currencyCode: currencyCode,
                size: 80,
                showRemaining: true
            )
            VStack(alignment: .leading, spacing: 4) {
                Text(scope.name)
                    .font(.headline)
                Text(monthName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding()
    }
}

#Preview {
    RemainingBudgetSnippetView(
        figures: BudgetFigures(spent: 70, income: 300, remaining: 230),
        scope: .category(.wants),
        currencyCode: "EUR",
        monthName: "October 2026"
    )
}
