//
//  MonthOverviewCards.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 16/05/2026.
//

import SwiftUI
import Charts

// MARK: - 1. Budget Rings Card
// Three concentric Activity-style rings, one per category.
// Each ring fills clockwise proportional to spending vs. allocation.
// Overspent rings turn red and show a flash dot at the overflow point.

struct BudgetRingsCard: View {
    @State var month: Month
    @State private var showRemaining = false
    @Environment(\.colorScheme) private var colorScheme

    private let ringDiameters: [CGFloat] = [220, 155, 90]
    private let lineWidth: CGFloat = 22

    private func fraction(for category: BudgetCategory) -> Double {
        let allocated = month.incomeAmount(for: category)
        guard allocated > 0 else { return 0 }
        return month.spentAmount(for: category) / allocated
    }

    var body: some View {
        GroupBox(label: Label("Budget Rings", systemImage: "circle.hexagongrid.fill")) {
            ZStack {
                ForEach(Array(BudgetCategory.allCases.enumerated()), id: \.offset) { index, category in
                    let f = fraction(for: category)
                    let capped = min(f, 1.0)
                    let isOver = month.overSpending(in: category)
                    let diameter = ringDiameters[index]
                    let fillColor: Color = isOver ? .red : category.color

                    // Track
                    Circle()
                        .trim(from: 0, to: 0.9999)
                        .stroke(fillColor.opacity(0.12), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                        .frame(width: diameter, height: diameter)
                        .rotationEffect(.degrees(-90))

                    // Progress fill
                    Circle()
                        .trim(from: 0, to: capped)
                        .stroke(
                            fillColor.gradient,
                            style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                        )
                        .frame(width: diameter, height: diameter)
                        .rotationEffect(.degrees(-90))

                    // Overflow flash dot at 100% mark when overspent
                    if isOver {
                        Circle()
                            .fill(.red)
                            .frame(width: lineWidth * 0.55, height: lineWidth * 0.55)
                            .offset(y: -diameter / 2)
                            .rotationEffect(.degrees(-90))
                    }
                }

                // Center button
                Button {
                    withAnimation(.spring(duration: 0.3)) { showRemaining.toggle() }
                } label: {
                    VStack(spacing: 1) {
                        Text(showRemaining ? "Remaining" : "Spent")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                        Text(
                            showRemaining
                                ? month.remainingAmountDisplay
                                : abs(month.negativeSpentAmount).formatted(
                                    .currency(code: month.currency.isoCode).precision(.fractionLength(0))
                                )
                        )
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(showRemaining && month.overSpent ? .red : (showRemaining && !month.overSpent ? .green : .primary))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    }
                    .frame(width: ringDiameters[2] - lineWidth * 2)
                }
                .buttonStyle(.borderless)
                .foregroundStyle(colorScheme == .light ? .black : .white)
            }
            .frame(height: 240)

            // Legend row
            HStack(spacing: DesignSystem.Spacing.medium.rawValue) {
                ForEach(Array(BudgetCategory.allCases.enumerated()), id: \.offset) { index, category in
                    let f = fraction(for: category)
                    let isOver = month.overSpending(in: category)
                    HStack(spacing: 5) {
                        Circle()
                            .fill(isOver ? .red : category.color)
                            .frame(width: 8, height: 8)
                        VStack(alignment: .leading, spacing: 0) {
                            Text(category.shortName)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text("\(Int(min(f, 9.99) * 100))%")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(isOver ? .red : .primary)
                        }
                    }
                    if index < BudgetCategory.allCases.count - 1 { Spacer() }
                }
            }
            .padding(.top, 4)
        }
        .groupBoxStyle(TrenteGroupBoxStyle())
    }
}

// MARK: - 2. Plan vs. Actual Card
// Outer thin ring: ideal budget allocation. Inner thick ring: actual spending.
// Instantly shows whether you're spending where you planned.

struct PlanVsActualCard: View {
    @State var month: Month

    private struct RingSlice: Identifiable {
        let id = UUID()
        let label: String
        let value: Double
        let color: Color
    }

    private var idealSlices: [RingSlice] {
        let total = Double(month.idealBudgetCents)
        guard total > 0 else {
            return [RingSlice(label: "Empty", value: 1, color: .gray)]
        }
        return BudgetCategory.allCases.map {
            RingSlice(
                label: $0.shortName,
                value: Double(month.idealRepartition[$0] ?? 0) / total,
                color: $0.color
            )
        }
    }

    private var actualSlices: [RingSlice] {
        let totalSpent = BudgetCategory.allCases.reduce(0.0) { $0 + month.spentAmount(for: $1) }
        guard totalSpent > 0 else {
            return [RingSlice(label: "Empty", value: 1, color: .gray)]
        }
        return BudgetCategory.allCases.map {
            RingSlice(
                label: $0.shortName,
                value: month.spentAmount(for: $0) / totalSpent,
                color: month.overSpending(in: $0) ? .red : $0.color
            )
        }
    }

    private var hasIdeal: Bool { month.idealBudgetCents > 0 }
    private var hasActual: Bool { abs(month.negativeSpentAmount) > 0 }

    var body: some View {
        GroupBox(label: Label("Plan vs. Actual", systemImage: "chart.pie")) {
            ZStack {
                // Outer ring: plan
                Chart {
                    ForEach(idealSlices) { slice in
                        SectorMark(
                            angle: .value(slice.label, slice.value),
                            innerRadius: .ratio(0.76),
                            outerRadius: .ratio(0.98),
                            angularInset: 2
                        )
                        .cornerRadius(4)
                        .foregroundStyle(
                            hasIdeal
                                ? AnyShapeStyle(slice.color.opacity(0.45))
                                : AnyShapeStyle(Color.gray.opacity(0.15))
                        )
                    }
                }
                .frame(height: 220)

                // Inner ring: actual
                Chart {
                    ForEach(actualSlices) { slice in
                        SectorMark(
                            angle: .value(slice.label, slice.value),
                            innerRadius: .ratio(0.46),
                            outerRadius: .ratio(0.73),
                            angularInset: 2
                        )
                        .cornerRadius(4)
                        .foregroundStyle(
                            hasActual
                                ? AnyShapeStyle(slice.color.gradient)
                                : AnyShapeStyle(Color.gray.opacity(0.1))
                        )
                    }
                }
                .frame(height: 220)

                // Center label
                VStack(spacing: 2) {
                    if month.overSpent {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                            .font(.title3)
                        Text("Over\nbudget")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                    } else {
                        Text(month.remainingAmountDisplay)
                            .font(.headline)
                            .fontWeight(.bold)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                        Text("left")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 80)
            }

            // Legend: outer dot (plan) + inner dot (actual)
            HStack(spacing: DesignSystem.Spacing.small.rawValue) {
                ForEach(BudgetCategory.allCases) { category in
                    HStack(spacing: 4) {
                        Circle().fill(category.color.opacity(0.45)).frame(width: 7, height: 7)
                        Circle().fill(category.color).frame(width: 7, height: 7)
                        Text(category.shortName)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    if category != BudgetCategory.allCases.last { Spacer() }
                }
            }
            .padding(.top, 4)
        }
        .groupBoxStyle(TrenteGroupBoxStyle())
    }
}

// MARK: - 3. Budget Meter Card
// A large 270° arc speedometer showing overall budget consumption.
// Arc color shifts green → yellow → orange → red as spending grows.
// Overspending is shown in full red with a bold label.

struct BudgetMeterCard: View {
    @State var month: Month

    private var totalSpent: Double { abs(month.negativeSpentAmount) }
    private var totalIncome: Double { month.incomeAmount }

    private var fraction: Double {
        guard totalIncome > 0 else { return 0 }
        return min(totalSpent / totalIncome, 1.5)
    }

    private var arcColor: Color {
        switch fraction {
        case ..<0.5:  return .green
        case ..<0.75: return .yellow
        case ..<1.0:  return .orange
        default:      return .red
        }
    }

    private var percentText: String {
        guard totalIncome > 0 else { return "–" }
        return "\(Int(min(fraction, 1.5) * 100))%"
    }

    var body: some View {
        GroupBox(label: Label("Budget Meter", systemImage: "speedometer")) {
            VStack(spacing: DesignSystem.Spacing.large.rawValue) {
                ZStack {
                    // Track
                    Circle()
                        .trim(from: 0, to: 0.75)
                        .stroke(
                            Color.gray.opacity(0.15),
                            style: StrokeStyle(lineWidth: 28, lineCap: .round)
                        )
                        .rotationEffect(.degrees(135))

                    // Fill
                    Circle()
                        .trim(from: 0, to: 0.75 * min(fraction, 1.0))
                        .stroke(
                            arcColor.gradient,
                            style: StrokeStyle(lineWidth: 28, lineCap: .round)
                        )
                        .rotationEffect(.degrees(135))

                    // Needle dot at tip
                    if totalIncome > 0 {
                        Circle()
                            .fill(.white)
                            .shadow(color: arcColor.opacity(0.5), radius: 4)
                            .frame(width: 14, height: 14)
                            .offset(y: -86)
                            .rotationEffect(.degrees(135 + 270 * min(fraction, 1.0)))
                    }

                    // Center content
                    VStack(spacing: 2) {
                        Text(percentText)
                            .font(.largeTitle)
                            .fontWeight(.heavy)
                            .foregroundStyle(arcColor)
                        Text("of budget used")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if month.overSpent {
                            Text("OVER BUDGET")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(.red))
                        }
                    }
                    .offset(y: 20)
                }
                .frame(height: 170)

                // Category status strip
                HStack(spacing: DesignSystem.Spacing.small.rawValue) {
                    ForEach(BudgetCategory.allCases) { category in
                        let isOver = month.overSpending(in: category)
                        VStack(spacing: 3) {
                            Image(systemName: isOver ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                                .foregroundStyle(isOver ? .red : category.color)
                                .font(.caption)
                            Text(category.shortName)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(isOver ? Color.red.opacity(0.1) : category.color.opacity(0.08))
                        )
                    }
                }
            }
        }
        .groupBoxStyle(TrenteGroupBoxStyle())
    }
}

// MARK: - 4. Spending Columns Card
// Three vertical thermometer columns, widths proportional to ideal allocation.
// Fill rises from the bottom; red overflow shown above the 100% line when overspent.

struct SpendingColumnsCard: View {
    @State var month: Month

    private var totalIdeal: Double { Double(month.idealBudgetCents) }

    private func idealWidth(for category: BudgetCategory, in total: CGFloat) -> CGFloat {
        guard totalIdeal > 0 else { return total / 3 }
        let frac = Double(month.idealRepartition[category] ?? 0) / totalIdeal
        return CGFloat(frac) * total
    }

    private func spentFraction(for category: BudgetCategory) -> Double {
        let allocated = month.incomeAmount(for: category)
        guard allocated > 0 else { return 0 }
        return month.spentAmount(for: category) / allocated
    }

    var body: some View {
        GroupBox(label: Label("Category Columns", systemImage: "chart.bar.xaxis.ascending")) {
            VStack(spacing: DesignSystem.Spacing.medium.rawValue) {
                GeometryReader { geo in
                    let totalWidth = geo.size.width
                    let columnHeight: CGFloat = 190
                    let gap: CGFloat = 10

                    HStack(alignment: .bottom, spacing: gap) {
                        ForEach(BudgetCategory.allCases) { category in
                            let idealW = idealWidth(for: category, in: totalWidth - gap * 2)
                            let fraction = spentFraction(for: category)
                            let capped = min(fraction, 1.0)
                            let isOver = month.overSpending(in: category)
                            let overflowFraction = isOver ? (fraction - 1.0) : 0.0
                            let overflowH = CGFloat(min(overflowFraction, 0.5)) * columnHeight

                            VStack(spacing: 0) {
                                // Overflow (above the budget line, red)
                                if isOver {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.red.gradient)
                                        .frame(width: idealW, height: overflowH)
                                }

                                // Budget line marker
                                if isOver {
                                    Rectangle()
                                        .fill(Color.red.opacity(0.6))
                                        .frame(width: idealW, height: 2)
                                }

                                ZStack(alignment: .bottom) {
                                    // Track
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(category.color.opacity(0.12))
                                        .frame(width: idealW, height: columnHeight)

                                    // Fill
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(isOver ? Color.red.opacity(0.4) : category.color.gradient)
                                        .frame(width: idealW, height: columnHeight * CGFloat(capped))

                                    // % label inside column
                                    if capped > 0.15 {
                                        Text("\(Int(capped * 100))%")
                                            .font(.caption2)
                                            .fontWeight(.bold)
                                            .foregroundStyle(isOver ? .red : category.color.darken(0.3))
                                            .padding(.bottom, 6)
                                    }
                                }
                            }
                        }
                    }
                    .frame(height: columnHeight + 40) // room for overflow
                }
                .frame(height: 230)

                // Category labels
                HStack {
                    ForEach(BudgetCategory.allCases) { category in
                        let isOver = month.overSpending(in: category)
                        VStack(spacing: 1) {
                            Text(category.shortName)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text(month.spentAmountDisplay(for: category))
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(isOver ? .red : .primary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .groupBoxStyle(TrenteGroupBoxStyle())
    }
}

// MARK: - 5. Daily Spending Card
// Bar chart of expenses grouped by day of month.
// Bars are colored by the day's dominant spending category.
// Today is highlighted; empty days show no bar.

struct DailySpendingCard: View {
    @State var month: Month

    private struct DailySpend: Identifiable {
        let id = UUID()
        let day: Int
        let amount: Double
        let color: Color
    }

    private var daysInMonth: Int {
        Calendar.current.range(of: .day, in: .month, for: month.startDate)?.count ?? 30
    }

    private var todayDay: Int {
        let cal = Calendar.current
        let startComponents = cal.dateComponents([.year, .month], from: month.startDate)
        let todayComponents = cal.dateComponents([.year, .month, .day], from: Date())
        guard startComponents.year == todayComponents.year,
              startComponents.month == todayComponents.month else { return -1 }
        return todayComponents.day ?? -1
    }

    private var dailyData: [DailySpend] {
        let cal = Calendar.current
        var byDay: [Int: (total: Int, categoryTotals: [BudgetCategory: Int])] = [:]

        for group in month.transactionGroups where group.type == .expense {
            let day = cal.component(.day, from: group.addedDate)
            var entry = byDay[day] ?? (0, [:])
            for txEntry in group.entries where txEntry.amountCents < 0 {
                let abs = abs(txEntry.amountCents)
                entry.total += abs
                entry.categoryTotals[txEntry.category, default: 0] += abs
            }
            byDay[day] = entry
        }

        return byDay.compactMap { day, data in
            guard data.total > 0 else { return nil }
            let dominant = data.categoryTotals.max(by: { $0.value < $1.value })?.key
            return DailySpend(day: day, amount: Double(data.total) / 100, color: dominant?.color ?? .gray)
        }.sorted { $0.day < $1.day }
    }

    private var hasData: Bool { !dailyData.isEmpty }
    private var totalSpent: Double { abs(month.negativeSpentAmount) }

    var body: some View {
        GroupBox(label: Label("Daily Spending", systemImage: "calendar.badge.clock")) {
            if hasData {
                VStack(spacing: DesignSystem.Spacing.medium.rawValue) {
                    Chart {
                        ForEach(dailyData) { item in
                            BarMark(
                                x: .value("Day", item.day),
                                y: .value("Amount", item.amount)
                            )
                            .foregroundStyle(item.color.gradient)
                            .cornerRadius(4)
                        }

                        if todayDay > 0 {
                            RuleMark(x: .value("Today", todayDay))
                                .foregroundStyle(Color.primary.opacity(0.25))
                                .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                                .annotation(position: .top, alignment: .center) {
                                    Text("Today")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                        }
                    }
                    .chartXAxis {
                        AxisMarks(values: .stride(by: 5)) { value in
                            AxisValueLabel {
                                if let day = value.as(Int.self) {
                                    Text("\(day)")
                                        .font(.caption2)
                                }
                            }
                            AxisGridLine()
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading) { _ in
                            AxisGridLine()
                        }
                    }
                    .frame(height: 200)

                    // Category color legend
                    HStack(spacing: DesignSystem.Spacing.medium.rawValue) {
                        ForEach(BudgetCategory.allCases) { category in
                            HStack(spacing: 4) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(category.color)
                                    .frame(width: 10, height: 10)
                                Text(category.shortName)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            if category != BudgetCategory.allCases.last { Spacer() }
                        }
                    }
                }
            } else {
                VStack(spacing: DesignSystem.Spacing.medium.rawValue) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("No spending recorded yet.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 240)
            }
        }
        .groupBoxStyle(TrenteGroupBoxStyle())
    }
}
