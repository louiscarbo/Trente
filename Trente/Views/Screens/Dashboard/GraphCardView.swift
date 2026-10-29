//
//  GraphCardView.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 17/04/2025.
//

import SwiftUI

struct GraphCardView: View {
    let figures: BudgetFigures
    let scope: BudgetScope
    let currency: Currency
    var size: CGFloat = 100

    @State private var showRemaining = false

    var body: some View {
        let exactAmount = figures.amount(showingRemaining: showRemaining)

        Button {
            withAnimation(.spring(duration: 0.35, bounce: 0.15)) { showRemaining.toggle() }
        } label: {
            GroupBox(label:
                Label(
                    scope.shortName,
                    systemImage: figures.isOverspent ? "exclamationmark.triangle.fill" : currency.sfSymbolGaugeName
                )
                .foregroundStyle(figures.isOverspent ? .red : scope.color)
            ) {
                VStack(spacing: 0) {
                    BudgetGaugeView(
                        figures: figures,
                        scope: scope,
                        currencyCode: currency.isoCode,
                        size: size,
                        showRemaining: showRemaining,
                        showsPercentage: true
                    )
                    .padding(8)

                    VStack(spacing: 2) {
                        HStack(spacing: 3) {
                            Text(exactAmount, format: .amount(currency.isoCode))
                                .foregroundStyle(figures.isOverspent ? .red : .primary)
                                .contentTransition(.numericText(value: exactAmount))
                            Text(verbatim: "/")
                                .foregroundStyle(.secondary)
                            Text(
                                figures.income,
                                format: .budget(currency.isoCode)
                            )
                            .foregroundStyle(.secondary)
                        }
                        .font(.caption.monospacedDigit())

                        (showRemaining ? Text("Left") : Text("Spent"))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .contentTransition(.opacity)
                    }
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                }
            }
            .groupBoxStyle(TrenteGroupBoxStyle())
        }
        .buttonStyle(PressableCardButtonStyle())
        .sensoryFeedback(.selection, trigger: showRemaining)
        .accessibilityLabel(Text(scope.name))
        .accessibilityValue(
            figures.accessibilityDescription(currencyCode: currency.isoCode, showingRemaining: showRemaining)
        )
        .accessibilityHint(showRemaining ? Text("Shows what you spent") : Text("Shows what's left"))
    }
}

private extension BudgetFigures {
    func amount(showingRemaining: Bool) -> Double {
        showingRemaining ? remaining : spent
    }

    func accessibilityDescription(currencyCode: String, showingRemaining: Bool) -> String {
        let amount = amount(showingRemaining: showingRemaining).formatted(.amount(currencyCode))
        let total = income.formatted(.budget(currencyCode))
        let description = showingRemaining
            ? String(localized: "\(amount) left of \(total)")
            : String(localized: "\(amount) spent of \(total)")
        guard isOverspent else { return description }
        return String(localized: "Over Budget") + ", " + description
    }
}

// MARK: BudgetGaugeView
struct BudgetGaugeView: View {
    var figures: BudgetFigures
    var scope: BudgetScope
    var currencyCode: String
    var size: CGFloat = 100
    var showRemaining = false
    var showsPercentage = false

    private var currencyFormat: FloatingPointFormatStyle<Double>.Currency {
        .budget(currencyCode)
    }

    private var displayedAmount: Double {
        figures.amount(showingRemaining: showRemaining)
    }

    private var percentage: Double {
        guard figures.income > 0 else { return 0 }
        return displayedAmount / figures.income
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
        Gauge(value: gaugeValue, in: 0...figures.income) {
            Text(scope.name)
        } currentValueLabel: {
            centerLabel
                .foregroundStyle(textColor)
        }
        .gaugeStyle(
            TrenteGaugeStyle(
                color: gaugeColor,
                diameter: size,
                highlightsRemaining: showRemaining
            )
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(scope.name))
        .accessibilityValue(figures.accessibilityDescription(currencyCode: currencyCode, showingRemaining: showRemaining))
    }

    @ViewBuilder
    private var centerLabel: some View {
        if showsPercentage {
            Text(percentage, format: .percent.precision(.fractionLength(0)))
                .font(.headline)
                .contentTransition(.numericText(value: percentage))
        } else {
            VStack(spacing: 0) {
                Text(displayedAmount, format: currencyFormat)
                    .font(.headline)
                    .contentTransition(.numericText(value: displayedAmount))
                Divider()
                    .frame(width: size / 2, height: 1)
                    .padding(2)
                Text(figures.income, format: currencyFormat)
                    .font(.subheadline)
            }
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
    let scopes: [BudgetScope] = [.all] + BudgetCategory.allCases.map { .category($0) }

    LazyVGrid(columns: [GridItem(), GridItem()]) {
        ForEach(scopes, id: \.self) { scope in
            GraphCardView(figures: month.figures(in: scope), scope: scope, currency: month.currency)
        }
    }
}
