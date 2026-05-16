//
//  MonthOverviewCards.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 16/05/2026.
//

import SwiftUI
import Charts

// MARK: - 1. Donut Overview Card

struct DonutOverviewCard: View {
    @State var month: Month
    @State private var showRemaining = false
    @Environment(\.colorScheme) private var colorScheme

    private struct Sector: Identifiable {
        let id = UUID()
        let label: String
        let value: Double
        let color: Color
    }

    private var totalSpent: Double { abs(month.negativeSpentAmount) }

    private var sectors: [Sector] {
        let categorySlices = BudgetCategory.allCases.compactMap { category -> Sector? in
            let spent = month.spentAmount(for: category)
            guard spent > 0 else { return nil }
            return Sector(label: category.shortName, value: spent, color: category.color)
        }

        if categorySlices.isEmpty {
            return [Sector(label: String(localized: "Empty"), value: 1, color: .gray)]
        }

        let remaining = month.remainingAmount
        if remaining > 0 {
            return categorySlices + [Sector(label: String(localized: "Remaining"), value: remaining, color: .gray)]
        }
        return categorySlices
    }

    private var hasData: Bool { totalSpent > 0 || month.incomeAmount > 0 }

    var body: some View {
        GroupBox(label: Label("Monthly Overview", systemImage: "chart.pie.fill")) {
            ZStack {
                Chart {
                    ForEach(sectors) { sector in
                        SectorMark(
                            angle: .value(sector.label, sector.value),
                            innerRadius: .ratio(0.58),
                            angularInset: 3
                        )
                        .cornerRadius(6)
                        .foregroundStyle(
                            hasData
                                ? AnyShapeStyle(sector.color.gradient)
                                : AnyShapeStyle(Color.gray.opacity(0.2))
                        )
                    }
                }
                .frame(height: 240)

                if hasData {
                    Button {
                        withAnimation(.spring(duration: 0.3)) {
                            showRemaining.toggle()
                        }
                    } label: {
                        VStack(spacing: 2) {
                            if showRemaining {
                                Text("Remaining")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Text(month.remainingAmountDisplay)
                                    .font(.system(.title2, design: .serif, weight: .semibold))
                                    .foregroundStyle(month.overSpent ? .red : .green)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.5)
                            } else {
                                Text("Spent")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Text(
                                    totalSpent.formatted(
                                        .currency(code: month.currency.isoCode).precision(.fractionLength(0))
                                    )
                                )
                                .font(.system(.title2, design: .serif, weight: .semibold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                            }
                        }
                        .frame(width: 120)
                    }
                    .buttonStyle(.borderless)
                    .foregroundStyle(colorScheme == .light ? .black : .white)
                } else {
                    Text("Add income and transactions\nto see your overview.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(width: 120)
                }
            }
        }
        .groupBoxStyle(TrenteGroupBoxStyle())
    }
}

// MARK: - 2. Category Progress Card

struct CategoryProgressCard: View {
    @State var month: Month

    var body: some View {
        GroupBox(label: Label("Category Breakdown", systemImage: "chart.bar.fill")) {
            VStack(spacing: DesignSystem.Spacing.large.rawValue) {
                ForEach(BudgetCategory.allCases) { category in
                    CategoryProgressRow(month: month, category: category)
                }

                Divider()

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Income")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(month.incomeAmountDisplay)
                            .font(.system(.subheadline, design: .serif, weight: .semibold))
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Remaining")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(month.remainingAmountDisplay)
                            .font(.system(.subheadline, design: .serif, weight: .semibold))
                            .foregroundStyle(month.overSpent ? .red : .primary)
                    }
                }
            }
        }
        .groupBoxStyle(TrenteGroupBoxStyle())
    }
}

private struct CategoryProgressRow: View {
    var month: Month
    var category: BudgetCategory

    private var spent: Double { month.spentAmount(for: category) }
    private var allocated: Double { month.incomeAmount(for: category) }
    private var progress: Double { allocated > 0 ? min(spent / allocated, 1.0) : 0 }
    private var isOverspent: Bool { month.overSpending(in: category) }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(category.shortName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text(month.spentAmountDisplay(for: category))
                    .font(.subheadline)
                    .foregroundStyle(isOverspent ? .red : .primary)
                Text("/ \(allocated.formatted(.currency(code: month.currency.isoCode).precision(.fractionLength(0))))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(category.color.opacity(0.2))
                    Capsule()
                        .fill(isOverspent ? Color.red.gradient : category.color.gradient)
                        .frame(width: geo.size.width * (progress > 0 ? max(progress, 0.02) : 0))
                }
            }
            .frame(height: 8)
        }
    }
}

// MARK: - 3. Month At a Glance Card

struct MonthAtAGlanceCard: View {
    @State var month: Month

    private var totalSpent: Double { abs(month.negativeSpentAmount) }

    var body: some View {
        GroupBox(label: Label("At a Glance", systemImage: "eye.fill")) {
            VStack(spacing: DesignSystem.Spacing.large.rawValue) {
                VStack(spacing: 4) {
                    Text(month.overSpent ? "Over budget" : "Remaining")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(month.remainingAmountDisplay)
                        .font(.system(.largeTitle, design: .serif, weight: .bold))
                        .foregroundStyle(month.overSpent ? .red : .primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.4)
                }

                Divider()

                HStack {
                    VStack(spacing: 2) {
                        Label("Income", systemImage: "arrow.down.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                        Text(month.incomeAmountDisplay)
                            .font(.system(.subheadline, design: .serif, weight: .semibold))
                    }
                    Spacer()
                    VStack(spacing: 2) {
                        Label("Spent", systemImage: "arrow.up.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.red)
                        Text(
                            totalSpent.formatted(
                                .currency(code: month.currency.isoCode).precision(.fractionLength(0))
                            )
                        )
                        .font(.system(.subheadline, design: .serif, weight: .semibold))
                    }
                }

                Divider()

                HStack(spacing: DesignSystem.Spacing.small.rawValue) {
                    ForEach(BudgetCategory.allCases) { category in
                        VStack(spacing: 4) {
                            Circle()
                                .fill(month.overSpending(in: category) ? Color.red : category.color)
                                .frame(width: 8, height: 8)
                            Text(category.shortName)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text(month.remainingAmountDisplay(for: category))
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(month.overSpending(in: category) ? .red : .primary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.6)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .groupBoxStyle(TrenteGroupBoxStyle())
    }
}
