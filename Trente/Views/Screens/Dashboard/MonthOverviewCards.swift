//
//  MonthOverviewCards.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 16/05/2026.
//

import SwiftUI
import Charts

// MARK: - Daily Spending Card
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
