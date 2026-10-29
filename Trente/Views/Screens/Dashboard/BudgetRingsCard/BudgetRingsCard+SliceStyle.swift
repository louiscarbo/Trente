//
//  BudgetRingsCard+SliceStyle.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 29/10/2026.
//

import SwiftUI

extension BudgetRingsCard {
    struct SliceStyle {
        let fill: Color
        let border: Color?
        let label: Color
        let opacity: Double

        init(kind: BudgetRings.SliceKind, isPlan: Bool) {
            switch kind {
            case .category(let category):
                fill = isPlan
                    ? category.color.darken(brightnessDrop: -0.1, saturationBoost: -0.2)
                    : category.color
                border = isPlan ? nil : category.color.darken(0.1)
                label = category.color.darken(0.8)
                opacity = 1
            case .remaining:
                fill = .gray
                border = isPlan ? nil : Color.gray.darken(0.1)
                label = .primary
                opacity = isPlan ? 0.3 : 0.4
            case .overspent:
                fill = .red
                border = isPlan ? nil : Color.red.darken(0.1)
                label = .white
                opacity = isPlan ? 0.5 : 1
            }
        }

        static func name(of kind: BudgetRings.SliceKind) -> String {
            switch kind {
            case .category(let category): category.shortName
            case .remaining: String(localized: "Left")
            case .overspent: String(localized: "Over")
            }
        }
    }
}
