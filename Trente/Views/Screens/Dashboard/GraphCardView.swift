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
    
    private var percentage: Double {
        let allocated = month.incomeAmount(in: scope)
        guard allocated > 0 else { return 0 }
        let amount = showRemaining ? month.remainingAmount(in: scope) : month.spentAmount(in: scope)
        return amount / allocated
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
                    systemImage: month.overSpending(in: scope) ? "exclamationmark.triangle.fill" : month.currency.sfSymbolGaugeName
                )
                .foregroundColor(month.overSpending(in: scope) ? .red : scope.color)
            ) {
                VStack(spacing: 0) {
                    BudgetGaugeView(
                        month: month,
                        scope: scope,
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

private struct PressableCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        PressedScale(isPressed: configuration.isPressed) {
            configuration.label
        }
    }
}

private struct PressedScale<Content: View>: View {
    var isPressed: Bool
    @ViewBuilder var content: Content
    
    @State private var isScaledDown = false
    @State private var releaseTask: Task<Void, Never>?
    
    var body: some View {
        content
            .scaleEffect(isScaledDown ? 0.97 : 1)
            .animation(.spring(duration: 0.25), value: isScaledDown)
            .onChange(of: isPressed) { _, pressed in
                releaseTask?.cancel()
                if pressed {
                    isScaledDown = true
                } else {
                    releaseTask = Task {
                        try? await Task.sleep(for: .milliseconds(100))
                        guard !Task.isCancelled else { return }
                        isScaledDown = false
                    }
                }
            }
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
    var showRemaining = false
    
    var gaugeColor: Color {
        if showRemaining {
            return month.overSpending(in: scope) ? .red : scope.color
        }
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
        if showRemaining && month.overSpending(in: scope) {
            1
        } else if month.overSpending(in: scope) {
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
                Text(showRemaining ? month.remainingAmountDisplay(in: scope) : month.spentAmountDisplay(in: scope))
                    .foregroundStyle(month.overSpending(in: scope) ? .red : .primary)
                    .contentTransition(.numericText(value: showRemaining ? month.remainingAmount(in: scope) : month.spentAmount(in: scope)))
            } minimumValueLabel: {
                Text("")
            } maximumValueLabel: {
                Text("\(month.incomeAmount(in: scope), format: .currency(code: month.currency.isoCode).precision(.fractionLength(0)))")
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
    init(month: Month, category: BudgetCategory, size: CGFloat = 100) {
        self.init(month: month, scope: .category(category), size: size, showRemaining: false)
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
