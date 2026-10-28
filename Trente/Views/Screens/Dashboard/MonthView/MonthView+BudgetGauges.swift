//
//  MonthView+BudgetGauges.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 27/10/2026.
//

import SwiftUI
import SwiftData

extension MonthView {
    struct BudgetGauges: View {
        var month: Month
        var size: CGFloat = 80

        var body: some View {
            VStack(spacing: 20) {
                HStack(spacing: 20) {
                    card(for: .all)
                    card(for: .category(.needs))
                }
                HStack(spacing: 20) {
                    card(for: .category(.wants))
                    card(for: .category(.savingsAndDebts))
                }
            }
        }

        private func card(for scope: BudgetScope) -> some View {
            GraphCardView(
                figures: month.figures(in: scope),
                scope: scope,
                currency: month.currency,
                size: size
            )
        }
    }
}
