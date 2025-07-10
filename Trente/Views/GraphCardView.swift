//
//  GraphCardView.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 17/04/2025.
//

import SwiftUI

struct GraphCardView: View {
    @State var month: Month
    @State var category: BudgetCategory
    var size: CGFloat = 100
    var scaleHorizontally: Bool = true
    
    var body: some View {
        GroupBox(label:
            Label(
                category.shortName,
                systemImage: month.overSpending(in: category) ? "exclamationmark.triangle.fill" : month.currency.sfSymbolGaugeName
            )
            .foregroundColor(month.overSpending(in: category) ? .red : category.color)
        ) {
            CategoryRemainingGaugeView(month: month, category: category, size: size)
                .padding(8)
        }
        .groupBoxStyle(TrenteGroupBoxStyle(scaleHorizontally: scaleHorizontally))
    }
}

// MARK: CategoryRemainingGaugeView
struct CategoryRemainingGaugeView: View {
    @State var month: Month
    @State var category: BudgetCategory
    
    var size: CGFloat = 100
    
    var gaugeColor: Color {
        if month.spentAmount(for: category) == 0 {
            return .gray
        }
        if month.overSpending(in: category) {
            return .red
        }
        return category.color
    }
    
    var textColor: Color {
        if month.overSpending(in: category) {
            return .red
        }
        return .primary
    }
    
    var gaugeValue: Double {
        if month.overSpending(in: category) {
            -1 * month.remainingAmount(for: category).truncatingRemainder(dividingBy: month.incomeAmount(for: category))
        } else {
            month.spentAmount(for: category)
        }
    }
    
    var body: some View {
        VStack {
            Gauge(value: gaugeValue, in: 0...month.incomeAmount(for: category)) {
                Text(category.name)
            } currentValueLabel: {
                Text(month.spentAmountDisplay(for: category))
                    .foregroundStyle(month.spentAmount(for: category) > month.incomeAmount(for: category) ? .red : .primary)
            } minimumValueLabel: {
                Text("")
            } maximumValueLabel: {
                Text("\(month.incomeAmount(for: category), format: .currency(code: month.currency.isoCode).precision(.fractionLength(0)))")
                    .foregroundStyle(textColor)
            }
            .gaugeStyle(TrenteGaugeStyle(color: gaugeColor, diameter: size))
        }
    }
}

#Preview {
    let month = Month.month1
    
    VStack {
        Color.red.frame(width: 400, height: 200)
            .gridCellColumns(2)
        HStack {
            GraphCardView(month: month, category: .needs)
            
            GraphCardView(month: month, category: .wants)
        }
        GraphCardView(month: month, category: .savingsAndDebts)
    }
}
