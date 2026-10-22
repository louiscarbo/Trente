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
    
    @State private var showRemaining = false

    private var figures: BudgetFigures {
        month.figures(in: scope)
    }

    private var percentage: Double {
        guard figures.income > 0 else { return 0 }
        let amount = showRemaining ? figures.remaining : figures.spent
        return amount / figures.income
    }
    
    private var caption: Text {
        let roundedPercentage = Int((percentage * 100).rounded())
        return showRemaining ? Text("\(roundedPercentage)% Left") : Text("\(roundedPercentage)% Spent")
    }
    
    var body: some View {
        Button {
            withAnimation(.spring(duration: 0.35, bounce: 0.15)) { showRemaining.toggle() }
        } label: {
            GroupBox(label:
                Label(
                    scope.shortName,
                    systemImage: figures.isOverspent ? "exclamationmark.triangle.fill" : month.currency.sfSymbolGaugeName
                )
                .foregroundColor(figures.isOverspent ? .red : scope.color)
            ) {
                VStack(spacing: 0) {
                    BudgetGaugeView(
                        figures: figures,
                        scope: scope,
                        currencyCode: month.currency.isoCode,
                        size: size,
                        showRemaining: showRemaining
                    )
                    .padding(8)
                    
                    caption
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .contentTransition(.opacity)
                }
            }
            .groupBoxStyle(TrenteGroupBoxStyle())
        }
        .buttonStyle(PressableCardButtonStyle())
        .sensoryFeedback(.selection, trigger: showRemaining)
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
    var figures: BudgetFigures
    var scope: BudgetScope
    var currencyCode: String
    var size: CGFloat = 100
    var showRemaining = false

    private var currencyFormat: FloatingPointFormatStyle<Double>.Currency {
        .currency(code: currencyCode).precision(.fractionLength(0))
    }

    var gaugeColor: Color {
        if showRemaining {
            return figures.isOverspent ? .red : scope.color
        }
        if figures.spent == 0 {
            return .gray
        }
        if figures.isOverspent {
            return .red
        }
        return scope.color
    }

    var textColor: Color {
        if figures.isOverspent {
            return .red
        }
        return .primary
    }

    var gaugeValue: Double {
        if showRemaining && figures.isOverspent {
            1
        } else if figures.isOverspent {
            -1 * figures.remaining.truncatingRemainder(dividingBy: figures.income)
        } else {
            figures.spent
        }
    }

    var body: some View {
        VStack {
            Gauge(value: gaugeValue, in: 0...figures.income) {
                Text(scope.name)
            } currentValueLabel: {
                Text(showRemaining ? figures.remaining : figures.spent, format: currencyFormat)
                    .foregroundStyle(figures.isOverspent ? .red : .primary)
                    .contentTransition(.numericText(value: showRemaining ? figures.remaining : figures.spent))
            } minimumValueLabel: {
                Text("")
            } maximumValueLabel: {
                Text(figures.income, format: currencyFormat)
                    .foregroundStyle(textColor)
            }
            .gaugeStyle(
                TrenteGaugeStyle(
                    color: gaugeColor,
                    diameter: size,
                    highlightsRemaining: showRemaining
                )
            )
        }
    }
}

extension BudgetGaugeView {
    init(figures: BudgetFigures, category: BudgetCategory, currencyCode: String, size: CGFloat = 100) {
        self.init(figures: figures, scope: .category(category), currencyCode: currencyCode, size: size, showRemaining: false)
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
