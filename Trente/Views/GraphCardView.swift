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
            .gaugeStyle(CategoryRemainingGaugeSytyle(color: gaugeColor, diameter: size))
        }
    }
}

// MARK: CategoryRemainingGaugeSytyle
struct CategoryRemainingGaugeSytyle: GaugeStyle {
    var color: Color
    var diameter: CGFloat = 100

    var gradient: Gradient {
        Gradient(colors: [adjustHue(of: color, by: -20), color])
    }

    func makeBody(configuration: Configuration) -> some View {
        var strokeWidth: CGFloat {
            diameter / 6
        }
        
        ZStack {
                Circle()
                    .trim(from: 0, to: 0.75 * configuration.value)
                    .stroke(
                        gradient,
                        style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(135))
                
                Circle()
                    .trim(from: 0, to: 0.75)
                    .stroke(
                        gradient.opacity(0.3),
                        style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(135))
                
                Circle()
                    .fill(Color.white)
                    .frame(width: 0.6*strokeWidth.rounded(), height: 0.6*strokeWidth.rounded())
                    .offset(y: -1 * diameter / 2)
                    .rotationEffect(.degrees(225 + 270 * configuration.value))
                
            VStack(spacing: 0) {
                configuration.currentValueLabel
                    .font(.headline)
                Divider()
                    .frame(width: diameter / 2, height: 1)
                    .padding(2)
                configuration.maximumValueLabel
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: diameter, height: diameter)
    }
    
    
    func adjustHue(of color: Color, by degrees: Double) -> Color {
        #if os(iOS)
        let uiColor = UIColor(color)
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0

        uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        hue = CGFloat((Double(hue) + degrees / 360).truncatingRemainder(dividingBy: 1))
        if hue < 0 { hue += 1 }

        return Color(hue: Double(hue), saturation: Double(saturation), brightness: Double(brightness) - 0.1, opacity: Double(alpha))
        #else
        return color
        #endif
    }
}

#Preview {
    let month = Month.month1
    
    VStack {
        Color.red.frame(width: 400, height: 200)
            .gridCellColumns(2)
        HStack {
            GraphCardView(month: month, category: .needs)
                .modelContainer(SampleDataProvider.shared.modelContainer)
            
            GraphCardView(month: month, category: .wants)
                .modelContainer(SampleDataProvider.shared.modelContainer)
        }
        GraphCardView(month: month, category: .savingsAndDebts)
            .modelContainer(SampleDataProvider.shared.modelContainer)
    }
}
