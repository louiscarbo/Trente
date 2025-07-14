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
    let formatter: NumberFormatter
    @Binding var isRepartitionComplete: Bool

    @State private var remainingAmount: Int = 0
    private var categories: [BudgetCategory] {
        repartition.keys.map { $0 }
    }

    init(repartition: Binding<[BudgetCategory: Int]>, amountToSplit: Int, formatter: NumberFormatter, isRepartitionComplete: Binding<Bool>) {
        self._repartition = repartition
        self.amountToSplit = amountToSplit
        self.formatter = formatter
        self._isRepartitionComplete = isRepartitionComplete
    }

    var body: some View {
        VStack(spacing: .medium) {
            VStack {
                let color: Color = .pink
                HStack {
                    Label("Amount to distribute",
                        systemImage: remainingAmount > 0 ? "exclamationmark.triangle.fill" : "checkmark.circle.fill"
                    )
                    Spacer()
                    Text(formatter.string(from: NSNumber(value: Double(remainingAmount) / 100.0)) ?? "")
                }
                .bold(remainingAmount < 100 && remainingAmount > 0)
                GeometryReader { geo in
                    let proportion = amountToSplit > 0
                        ? CGFloat(remainingAmount) / CGFloat(amountToSplit)
                        : 0

                    ZStack(alignment: .leading) {
                        color.lighten(0.25)

                        Rectangle()
                            .fill(color.gradient)
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
                    amountToSplit: amountToSplit,
                    formatter: formatter
                )
            }
        }
        .onAppear {
            let allocatedAmount = repartition.values.reduce(0, +)
            remainingAmount = amountToSplit - allocatedAmount
            isRepartitionComplete = remainingAmount == 0
        }
        .onChange(of: remainingAmount) { _, newValue in
            isRepartitionComplete = newValue == 0
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
    let formatter: NumberFormatter

    @State private var timer: Timer?
    @State private var isLongPressing = false

    var body: some View {
        VStack(spacing: .small) {
            Text(category.name)
                .font(.subheadline)
            HStack {
                let decreaseAction = {
                    withAnimation(.spring) {
                        let currentValue = repartition[category] ?? 0
                        let amountToDecrease = min(100, currentValue % 100 == 0 ? 100 : currentValue % 100)
                        let newValue = max(0, currentValue - amountToDecrease)
                        let delta = newValue - currentValue // will be negative or zero
                        repartition[category] = newValue
                        remainingAmount -= delta
                    }
                }

                Button(action: decreaseAction, label: {
                    Image(systemName: "minus")
                })
                .frame(width: 40, height: 60)
                .buttonStyle(TrenteSliderButtonStyle(color: category.color))
                .disabled((repartition[category] ?? 0) == 0)
                .simultaneousGesture(LongPressGesture(minimumDuration: 0.5).onEnded { _ in
                    isLongPressing = true
                    timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                        decreaseAction()
                    }
                })
                .simultaneousGesture(DragGesture(minimumDistance: 0).onEnded { _ in
                    if isLongPressing {
                        timer?.invalidate()
                        timer = nil
                        isLongPressing = false
                    }
                })

                let maxValueForSlider = (repartition[category] ?? 0) + remainingAmount

                RepartitionSlider(
                    color: category.color,
                    value: Binding(
                        get: { repartition[category] ?? 0 },
                        set: { newValue in
                            let oldValue = repartition[category] ?? 0
                            let clampedNewValue = min(newValue, oldValue + remainingAmount)
                            let roundedValue = (clampedNewValue / 100) * 100
                            let finalValue = min(roundedValue, oldValue + remainingAmount)
                            
                            let delta = finalValue - oldValue

                            repartition[category] = finalValue
                            remainingAmount -= delta
                        }
                    ),
                    total: amountToSplit,
                    maxValue: maxValueForSlider,
                    formatter: formatter
                )

                let increaseAction = {
                    withAnimation(.spring) {
                        let currentValue = repartition[category] ?? 0
                        let amountToIncrease = min(100, remainingAmount)
                        let newValue = min(currentValue + amountToIncrease, currentValue + remainingAmount)
                        let delta = newValue - currentValue // will be positive or zero
                        repartition[category] = newValue
                        remainingAmount -= delta
                    }
                }

                Button(action: increaseAction, label: {
                    Image(systemName: "plus")
                })
                .frame(width: 40, height: 60)
                .buttonStyle(TrenteSliderButtonStyle(color: category.color))
                .disabled(remainingAmount == 0)
                .simultaneousGesture(LongPressGesture(minimumDuration: 0.5).onEnded { _ in
                    isLongPressing = true
                    timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                        increaseAction()
                    }
                })
                .simultaneousGesture(DragGesture(minimumDistance: 0).onEnded { _ in
                    if isLongPressing {
                        timer?.invalidate()
                        timer = nil
                        isLongPressing = false
                    }
                })
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
    let formatter: NumberFormatter

    @State private var scale: CGFloat = 1.0

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

                let textView = Text(formatter.string(from: NSNumber(value: Double(value) / 100.0)) ?? "")
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
            .scaleEffect(x: scale, y: 1.0)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { drag in
                        let pct = min(max(0, drag.location.x / width), 1)
                        let rawNewValue = Int(round(pct * CGFloat(total)))
                        let roundedNewValue = (rawNewValue / 100) * 100
                        let clampedNewValue = min(roundedNewValue, maxValue)
                        value = clampedNewValue
                    }
            )
            .sensoryFeedback(.selection, trigger: value)
            .onChange(of: value) { _, _ in
                withAnimation(.bouncy(duration: 0.2)) {
                    scale = 1.02
                } completion: {
                    withAnimation(.bouncy(duration: 0.2)) {
                        scale = 1.0
                    }
                }
            }
        }
        .frame(height: 60)
    }
}

#Preview {
    @Previewable @State var repartition: [BudgetCategory: Int] = Dictionary(
            uniqueKeysWithValues: BudgetCategory.allCases.map { ($0, 0) }
        )
    @Previewable @State var isRepartitionComplete = false
    let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "EUR"
        return formatter
    }()

    VStack {
        GroupBox(label: Label("Income Repartition", systemImage: "chart.pie.fill")) {
            IncomeRepartitionComponent(
                repartition: $repartition,
                amountToSplit: 860_30,
                formatter: formatter,
                isRepartitionComplete: $isRepartitionComplete
            )
        }
        .groupBoxStyle(TrenteGroupBoxStyle())
        Text("Is Repartition Complete: \(isRepartitionComplete ? "Yes" : "No")")
        Spacer()
            .frame(height: 300)
    }
    .padding()
}
