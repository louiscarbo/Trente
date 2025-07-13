//
//  IncomeRepartitionView.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 12/07/2025.
//

import SwiftUI

struct IncomeRepartitionComponent: View {
    @Binding var repartition: [BudgetCategory: Int]
    let amountToSplit: Int
    let categories: [BudgetCategory]

    @State private var remainingAmount: Int = 0

    init(repartition: Binding<[BudgetCategory: Int]>, amountToSplit: Int, categories: [BudgetCategory]) {
        self._repartition = repartition
        self.amountToSplit = amountToSplit
        self.categories = categories
    }

    var body: some View {
        VStack(spacing: .small) {
            GeometryReader { geo in
                let color = Color.pink
                let proportion = amountToSplit > 0
                    ? CGFloat(remainingAmount) / CGFloat(amountToSplit)
                    : 0

                ZStack(alignment: .leading) {
                    color.opacity(0.3)

                    Capsule()
                        .fill(color)
                        .frame(width: proportion * geo.size.width + 10)
                }
            }
            .frame(height: 20)
            .clipShape(RoundedRectangle(cornerRadius: .large))

            ForEach(categories, id: \.self) { category in
                HStack {
                    HStack {
                        Button {
                            withAnimation(.bouncy) {
                                let currentValue = repartition[category] ?? 0
                                let amountToDecrease = 5
                                let newValue = max(0, currentValue - amountToDecrease)
                                let delta = newValue - currentValue // will be negative or zero
                                repartition[category] = newValue
                                remainingAmount -= delta
                            }
                        } label: {
                            Image(systemName: "minus")
                        }

                        let maxValueForSlider = (repartition[category] ?? 0) + remainingAmount

                        RepartitionSlider(
                            color: category.color,
                            value: Binding(
                                get: { repartition[category] ?? 0 },
                                set: { newValue in
                                    let oldValue = repartition[category] ?? 0
                                    let clampedNewValue = min(newValue, oldValue + remainingAmount)
                                    let delta = clampedNewValue - oldValue

                                    repartition[category] = clampedNewValue
                                    remainingAmount -= delta
                                }
                            ),
                            total: amountToSplit,
                            maxValue: maxValueForSlider
                        )

                        Button {
                            withAnimation {
                                let currentValue = repartition[category] ?? 0
                                let amountToIncrease = 5
                                let newValue = min(currentValue + amountToIncrease, currentValue + remainingAmount)
                                let delta = newValue - currentValue // will be positive or zero
                                repartition[category] = newValue
                                remainingAmount -= delta
                            }
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
        }
        .padding()
        .onAppear {
            let allocatedAmount = repartition.values.reduce(0, +)
            remainingAmount = amountToSplit - allocatedAmount
        }
    }
}

// MARK: - Custom Slider View
struct RepartitionSlider: View {
    let color: Color
    @Binding var value: Int
    let total: Int
    let maxValue: Int

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            // Compute current fill‐portion (0…1)
            let proportion = total > 0
                ? CGFloat(value) / CGFloat(total)
                : 0

            ZStack(alignment: .leading) {
                color.opacity(0.3)

                Rectangle()
                    .fill(color)
                    .frame(width: proportion * width)

                Capsule()
                    .fill(color)
                    .frame(width: 20)
                    .position(
                        x: max(0, min(proportion * width, width)),
                        y: geo.size.height / 2
                    )
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { drag in
                                // Map drag x-position to new value
                                let pct = min(max(0, drag.location.x / width), 1)
                                let rawNewValue = Int(round(pct * CGFloat(total)))
                                let clampedNewValue = min(rawNewValue, maxValue)
                                value = clampedNewValue
                            }
                    )
            }
        }
        .frame(height: 80)
        .clipShape(RoundedRectangle(cornerRadius: .large))
    }
}

#Preview {
    @Previewable @State var repartition: [BudgetCategory: Int] = Dictionary(
        uniqueKeysWithValues: BudgetCategory.allCases.map { ($0, 600 / BudgetCategory.allCases.count) }
    )
    IncomeRepartitionComponent(repartition: $repartition, amountToSplit: 600, categories: BudgetCategory.allCases)
}
