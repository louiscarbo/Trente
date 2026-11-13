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

    @State private var showRemaining = true

    var body: some View {
        let isOverBudget = figures.isOverBudget(in: scope)
        let showsExtra = showRemaining && figures.extraSaved(in: scope) > 0
        let exactAmount = figures.amount(showingRemaining: showRemaining, in: scope)

        Button {
            withAnimation(.spring(duration: 0.35, bounce: 0.15)) { showRemaining.toggle() }
        } label: {
            GroupBox(label:
                Label(
                    scope.shortName,
                    systemImage: isOverBudget ? "exclamationmark.triangle.fill" : currency.sfSymbolGaugeName
                )
                .foregroundStyle(isOverBudget ? .red : scope.color)
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
                            Text(exactAmount, format: .amount(currency.isoCode).sign(strategy: showsExtra ? .always() : .automatic))
                                .foregroundStyle(isOverBudget ? .red : .primary)
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

                        caption(showsExtra: showsExtra)
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
            figures.accessibilityDescription(currencyCode: currency.isoCode, showingRemaining: showRemaining, in: scope)
        )
        .accessibilityHint(showRemaining ? Text("Shows what you spent") : Text("Shows what's left"))
    }

    private func caption(showsExtra: Bool) -> Text {
        if showsExtra {
            return Text("Extra")
        }
        return showRemaining ? Text("Left") : Text("Spent")
    }
}

private extension BudgetFigures {
    func amount(showingRemaining: Bool, in scope: BudgetScope) -> Double {
        guard showingRemaining else { return spent }
        let extra = extraSaved(in: scope)
        return extra > 0 ? extra : remaining
    }

    func accessibilityDescription(currencyCode: String, showingRemaining: Bool, in scope: BudgetScope) -> String {
        let amount = amount(showingRemaining: showingRemaining, in: scope).formatted(.amount(currencyCode))
        let total = income.formatted(.budget(currencyCode))
        if showingRemaining && extraSaved(in: scope) > 0 {
            return String(localized: "\(amount) extra, above \(total)")
        }
        let description = showingRemaining
            ? String(localized: "\(amount) left of \(total)")
            : String(localized: "\(amount) spent of \(total)")
        guard isOverBudget(in: scope) else { return description }
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
        figures.amount(showingRemaining: showRemaining, in: scope)
    }

    private var isOverBudget: Bool {
        figures.isOverBudget(in: scope)
    }

    private var showsExtra: Bool {
        showRemaining && figures.extraSaved(in: scope) > 0
    }

    private var percentage: Double {
        guard figures.income > 0 else { return 0 }
        return displayedAmount / figures.income
    }

    var gaugeColor: Color {
        if showRemaining {
            return isOverBudget ? .red : scope.color
        }
        if figures.spent == 0 {
            return .gray
        }
        if isOverBudget {
            return .red
        }
        return scope.color
    }

    var textColor: Color {
        if isOverBudget {
            return .red
        }
        return .primary
    }

    private var highlight: GaugeHighlight {
        figures.gaugeHighlight(showingRemaining: showRemaining, in: scope)
    }

    var body: some View {
        Gauge(value: figures.gaugeIndicator(in: scope)) {
            Text(scope.name)
        } currentValueLabel: {
            centerLabel
                .foregroundStyle(textColor)
        }
        .gaugeStyle(
            TrenteGaugeStyle(
                color: gaugeColor,
                diameter: size,
                highlightsLeft: highlight.left,
                highlightsSpent: highlight.spent
            )
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(scope.name))
        .accessibilityValue(
            figures.accessibilityDescription(currencyCode: currencyCode, showingRemaining: showRemaining, in: scope)
        )
    }

    @ViewBuilder
    private var centerLabel: some View {
        if showsPercentage {
            Text(percentage, format: .percent.precision(.fractionLength(0)).sign(strategy: showsExtra ? .always() : .automatic))
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, size / 12 + 2)
                .contentTransition(.numericText(value: percentage))
        } else {
            VStack(spacing: 0) {
                Text(displayedAmount, format: currencyFormat.sign(strategy: showsExtra ? .always() : .automatic))
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
