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

        @Environment(\.dynamicTypeSize) private var dynamicTypeSize

        private var gaugeSize: CGFloat {
            dynamicTypeSize.isAccessibilitySize ? 160 : 80
        }

        private var rowLayout: AnyLayout {
            dynamicTypeSize.isAccessibilitySize
                ? AnyLayout(VStackLayout(spacing: 20))
                : AnyLayout(HStackLayout(spacing: 20))
        }

        var body: some View {
            VStack(spacing: 20) {
                rowLayout {
                    card(for: .all)
                    card(for: .category(.needs))
                }
                rowLayout {
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
                size: gaugeSize
            )
        }
    }
}
