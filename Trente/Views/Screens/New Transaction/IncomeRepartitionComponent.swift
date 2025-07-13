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
        VStack(spacing: .medium) {
            VStack {
                let color: Color = .pink
                HStack {
                    Text("Amount to distribute")
                    Spacer()
                    Text("\(remainingAmount) €")
                }
                GeometryReader { geo in
                    let proportion = amountToSplit > 0
                        ? CGFloat(remainingAmount) / CGFloat(amountToSplit)
                        : 0

                    ZStack(alignment: .leading) {
                        color.lighten(0.25)

                        Rectangle()
                            .fill(color)
                            .frame(width: proportion * geo.size.width + 3)
                    }
                }
                .frame(height: 20)
                .clipShape(Capsule())
                .overlay {
                    RoundedRectangle(cornerRadius: .large)
                        .strokeBorder(
                            color.darken(0.1),
                            lineWidth: 3
                        )
                }
            }

            ForEach(categories, id: \.self) { category in
                BudgetCategorySliderRow(
                    category: category,
                    repartition: $repartition,
                    remainingAmount: $remainingAmount,
                    amountToSplit: amountToSplit
                )
            }
        }
        .onAppear {
            let allocatedAmount = repartition.values.reduce(0, +)
            remainingAmount = amountToSplit - allocatedAmount
        }
    }
}

struct TrenteSliderButtonStyle: ButtonStyle {
    let color: Color
    @Environment(\.isEnabled) private var isEnabled: Bool

    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: .large)
                .fill(color)
            configuration.label
                .bold()
                .opacity(isEnabled ? 1.0 : 0.3)
            RoundedRectangle(cornerRadius: .large)
                .strokeBorder(color.darken(0.1), lineWidth: 3)
        }
        .scaleEffect(isEnabled ? (configuration.isPressed ? 0.95 : 1.0) : 1)
        .opacity(isEnabled ? (configuration.isPressed ? 0.8 : 1.0) : 1)
        .tint(color.darken(0.8))
    }
}

struct BudgetCategorySliderRow: View {
    let category: BudgetCategory
    @Binding var repartition: [BudgetCategory: Int]
    @Binding var remainingAmount: Int
    let amountToSplit: Int

    var body: some View {
        VStack(spacing: .small) {
            Text(category.name)
                .font(.subheadline)
            HStack {
                Button {
                    withAnimation(.spring) {
                        let currentValue = repartition[category] ?? 0
                        let amountToDecrease = 1
                        let newValue = max(0, currentValue - amountToDecrease)
                        let delta = newValue - currentValue // will be negative or zero
                        repartition[category] = newValue
                        remainingAmount -= delta
                    }
                } label: {
                    Image(systemName: "minus")
                }
                .frame(width: 40, height: 60)
                .buttonStyle(TrenteSliderButtonStyle(color: category.color))

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
                    withAnimation(.spring) {
                        let currentValue = repartition[category] ?? 0
                        let amountToIncrease = 1
                        let newValue = min(currentValue + amountToIncrease, currentValue + remainingAmount)
                        let delta = newValue - currentValue // will be positive or zero
                        repartition[category] = newValue
                        remainingAmount -= delta
                    }
                } label: {
                    Image(systemName: "plus")
                }
                .frame(width: 40, height: 60)
                .buttonStyle(TrenteSliderButtonStyle(color: category.color))
            }
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
            let proportion = total > 0 ? CGFloat(value) / CGFloat(total) : 0
            let fillWidth = proportion * width + 3

            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(color.darken(brightnessDrop: -0.10, saturationBoost: -0.2))

                Rectangle()
                    .fill(color)
                    .frame(width: fillWidth)

                let textView = Text("\(value) €")
                    .font(.title)
                    .bold()
                    .frame(maxWidth: .infinity, alignment: .center)

                textView
                    .foregroundColor(color.lighten(0.5))
                    .mask(
                        HStack {
                            Rectangle().frame(width: fillWidth)
                            Spacer(minLength: 0)
                        }
                    )

                textView
                    .foregroundColor(color.darken(0.8))
                    .mask(
                        HStack {
                            Spacer(minLength: 0)
                            Rectangle().frame(width: width - fillWidth)
                        }
                    )
            }
            .frame(width: width)
            .overlay {
                RoundedRectangle(cornerRadius: .large)
                    .strokeBorder(
                        color.darken(0.1),
                        lineWidth: 3
                    )
            }
            .clipShape(RoundedRectangle(cornerRadius: .large))
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { drag in
                        let pct = min(max(0, drag.location.x / width), 1)
                        let rawNewValue = Int(round(pct * CGFloat(total)))
                        let clampedNewValue = min(rawNewValue, maxValue)
                        value = clampedNewValue
                    }
            )
        }
        .frame(height: 60)
    }
}

#Preview {
    @Previewable @State var repartition: [BudgetCategory: Int] = Dictionary(
        uniqueKeysWithValues: BudgetCategory.allCases.map { ($0, 100 / BudgetCategory.allCases.count) }
    )
    VStack {
        GroupBox(label: Label("Income Repartition", systemImage: "chart.pie.fill")) {
            IncomeRepartitionComponent(repartition: $repartition, amountToSplit: 100, categories: BudgetCategory.allCases)
        }
        .groupBoxStyle(TrenteGroupBoxStyle())
        Spacer()
            .frame(height: 300)
    }
    .padding()
}
