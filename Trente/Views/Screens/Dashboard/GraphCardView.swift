//
//  GraphCardView.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 17/04/2025.
//

import SwiftUI

struct GraphCardView: View {
    var month: Month
    var scope: BudgetScope
    var size: CGFloat = 100
    
    var body: some View {
        GroupBox(label:
            Label(
                scope.shortName,
                systemImage: month.overSpending(in: scope) ? "exclamationmark.triangle.fill" : month.currency.sfSymbolGaugeName
            )
            .foregroundColor(month.overSpending(in: scope) ? .red : scope.color)
        ) {
            BudgetGaugeView(month: month, scope: scope, size: size)
                .padding(8)
        }
        .groupBoxStyle(TrenteGroupBoxStyle())
    }
}

extension GraphCardView {
    init(month: Month, category: BudgetCategory, size: CGFloat = 100) {
        self.init(month: month, scope: .category(category), size: size)
    }
}

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

// MARK: BudgetGaugeView
struct BudgetGaugeView: View {
    var month: Month
    var scope: BudgetScope
    var size: CGFloat = 100
    
    var gaugeColor: Color {
        if month.spentAmount(in: scope) == 0 {
            return .gray
        }
        if month.overSpending(in: scope) {
            return .red
        }
        return scope.color
    }
    
    var textColor: Color {
        if month.overSpending(in: scope) {
            return .red
        }
        return .primary
    }
    
    var gaugeValue: Double {
        if month.overSpending(in: scope) {
            -1 * month.remainingAmount(in: scope).truncatingRemainder(dividingBy: month.incomeAmount(in: scope))
        } else {
            month.spentAmount(in: scope)
        }
    }
    
    var body: some View {
        VStack {
            Gauge(value: gaugeValue, in: 0...month.incomeAmount(in: scope)) {
                Text(scope.name)
            } currentValueLabel: {
                Text(month.spentAmountDisplay(in: scope))
                    .foregroundStyle(month.spentAmount(in: scope) > month.incomeAmount(in: scope) ? .red : .primary)
            } minimumValueLabel: {
                Text("")
            } maximumValueLabel: {
                Text("\(month.incomeAmount(in: scope), format: .currency(code: month.currency.isoCode).precision(.fractionLength(0)))")
                    .foregroundStyle(textColor)
            }
            .gaugeStyle(TrenteGaugeStyle(color: gaugeColor, diameter: size))
        }
    }
}

extension BudgetGaugeView {
    init(month: Month, category: BudgetCategory, size: CGFloat = 100) {
        self.init(month: month, scope: .category(category), size: size)
    }
}

#Preview {
    let month = Month.month1
    
    VStack {
        HStack {
            GraphCardView(month: month, scope: .all)
            
            GraphCardView(month: month, category: .needs)
        }
        HStack {
            GraphCardView(month: month, category: .wants)
            
            GraphCardView(month: month, category: .savingsAndDebts)
        }
    }
}
