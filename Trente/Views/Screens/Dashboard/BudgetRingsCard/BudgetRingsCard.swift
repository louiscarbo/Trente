//
//  BudgetRingsCard.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 29/10/2026.
//

import SwiftUI

struct BudgetRingsCard: View {
    let rings: BudgetRings

    @State private var lens: BudgetRings.Lens = .split

    var body: some View {
        let isSwitchable = rings.hasSpending
        let shownLens = isSwitchable ? lens : .split

        Button {
            withAnimation(.spring(duration: 0.4, bounce: 0.2)) {
                lens = lens == .split ? .leftToSpend : .split
            }
        } label: {
            GroupBox(label:
                HStack {
                    cardTitle(for: shownLens)
                    Spacer()
                    if isSwitchable { switchHint }
                }
            ) {
                VStack(spacing: DesignSystem.Spacing.medium.rawValue) {
                    Rings(
                        segments: rings.segments(in: shownLens),
                        plan: rings.plan(in: shownLens),
                        centerShare: rings.centerShare(in: shownLens),
                        centerCaption: centerCaption(for: shownLens),
                        isOverspent: rings.isOverspent,
                        showsCaptionAsAlert: shownLens == .leftToSpend && rings.isOverspent
                    )
                    Legend()
                }
            }
            .groupBoxStyle(TrenteGroupBoxStyle())
        }
        .buttonStyle(PressableCardButtonStyle())
        .disabled(!isSwitchable)
        .sensoryFeedback(.selection, trigger: lens)
    }

    private func cardTitle(for lens: BudgetRings.Lens) -> some View {
        let showsAlert = lens == .leftToSpend && rings.isOverspent
        let title = switch lens {
        case .split: String(localized: "Spending Split")
        case .leftToSpend where showsAlert: String(localized: "Overspent")
        case .leftToSpend: String(localized: "Left to Spend")
        }
        return Label(title, systemImage: showsAlert ? "exclamationmark.triangle.fill" : "chart.pie.fill")
            .foregroundStyle(showsAlert ? .red : .primary)
            .contentTransition(.opacity)
            .animation(.easeInOut(duration: 0.2), value: title)
    }

    private func centerCaption(for lens: BudgetRings.Lens) -> String {
        switch lens {
        case .split: String(localized: "Spent")
        case .leftToSpend where rings.isOverspent: String(localized: "Over")
        case .leftToSpend: String(localized: "Left")
        }
    }

    private var switchHint: some View {
        Image(systemName: "chevron.up.chevron.down")
            .font(.caption.bold())
            .foregroundStyle(.secondary)
    }
}

#Preview {
    let income: [BudgetCategory: Double] = [.needs: 1500, .wants: 900, .savingsAndDebts: 600]
    let months: [[BudgetCategory: Double]] = [
        [.needs: 1100, .wants: 620, .savingsAndDebts: 400],
        [.needs: 1100, .wants: 1150, .savingsAndDebts: 300],
        [.needs: 1600, .wants: 1200, .savingsAndDebts: 500],
        [:]
    ]

    ScrollView {
        VStack(spacing: 20) {
            ForEach(months.indices, id: \.self) { index in
                BudgetRingsCard(rings: BudgetRings(spent: months[index], income: income))
            }
        }
        .padding()
    }
}
