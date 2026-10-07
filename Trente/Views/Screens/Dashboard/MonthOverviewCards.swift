//
//  MonthOverviewCards.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 16/05/2026.
//

import SwiftUI
import Charts

// MARK: - Daily Spending Card
// Bar chart of expenses grouped by day, stacked by category (needs/wants/savings split
// per day instead of a single "dominant category" color).
// Tap the whole card to flip between Month (every day, no scroll) and Week (7 days,
// scrollable to any week via chartScrollableAxes). Today is highlighted. Tap/drag a bar
// to see that day's breakdown in the dock below the chart; with nothing selected, the
// dock falls back to the totals for whatever window is currently visible.

struct DailySpendingCard: View {
    @State var month: Month

    @State private var mode: SpendingWindowMode = .month
    @State private var scrollPosition: Date
    @State private var selectedDate: Date?

    private let calendar = Calendar.current

    init(month: Month) {
        self._month = State(initialValue: month)
        let calendar = Calendar.current
        let isCurrentMonth = calendar.isDate(Date(), equalTo: month.startDate, toGranularity: .month)
        let monthStartDay = calendar.startOfDay(for: month.startDate)
        let anchor = isCurrentMonth ? calendar.startOfDay(for: Date()) : calendar.startOfDay(for: month.endDate())
        let candidate = calendar.date(byAdding: .day, value: -6, to: anchor) ?? monthStartDay
        self._scrollPosition = State(initialValue: max(candidate, monthStartDay))
    }

    private enum SpendingWindowMode: Hashable {
        case month, week
    }

    private struct DailySpend: Identifiable {
        let date: Date
        let amounts: [BudgetCategory: Double]
        var id: Date { date }
        var total: Double { amounts.values.reduce(0, +) }
    }

    private var monthStartDay: Date { calendar.startOfDay(for: month.startDate) }
    private var monthEndDay: Date { calendar.startOfDay(for: month.endDate()) }

    private var daysInMonth: Int {
        calendar.range(of: .day, in: .month, for: month.startDate)?.count ?? 30
    }

    private var isCurrentMonth: Bool {
        calendar.isDate(Date(), equalTo: month.startDate, toGranularity: .month)
    }

    private var todayDate: Date? {
        guard isCurrentMonth else { return nil }
        return calendar.startOfDay(for: Date())
    }

    private var dailyData: [DailySpend] {
        var byDay: [Date: [BudgetCategory: Int]] = [:]

        for group in month.transactionGroups where group.type == .expense {
            let day = calendar.startOfDay(for: group.addedDate)
            var entry = byDay[day] ?? [:]
            for txEntry in group.entries where txEntry.amountCents < 0 {
                entry[txEntry.category, default: 0] += abs(txEntry.amountCents)
            }
            byDay[day] = entry
        }

        return byDay.map { day, amounts in
            DailySpend(date: day, amounts: amounts.mapValues { Double($0) / 100 })
        }.sorted { $0.date < $1.date }
    }

    private var maxDailyTotal: Double {
        max(dailyData.map(\.total).max() ?? 0, 1)
    }

    private var hasData: Bool { !dailyData.isEmpty }

    private func day(on date: Date) -> DailySpend? {
        dailyData.first { calendar.isDate($0.date, inSameDayAs: date) }
    }

    private func defaultWeekStart() -> Date {
        let anchor = todayDate ?? monthEndDay
        let candidate = calendar.date(byAdding: .day, value: -6, to: anchor) ?? monthStartDay
        return max(candidate, monthStartDay)
    }

    private var visibleDays: [DailySpend] {
        switch mode {
        case .month:
            return dailyData
        case .week:
            let start = calendar.startOfDay(for: scrollPosition)
            let end = calendar.date(byAdding: .day, value: 6, to: start) ?? start
            return dailyData.filter { (start...end).contains($0.date) }
        }
    }

    private func formattedAmount(_ value: Double) -> String {
        value.formatted(.currency(code: month.currency.isoCode).precision(.fractionLength(0)))
    }

    private func totalAndAverage(for days: [DailySpend]) -> (total: Double, average: Double) {
        let total = days.reduce(0) { $0 + $1.total }
        let activeDays = days.filter { $0.total > 0 }.count
        return (total, activeDays > 0 ? total / Double(activeDays) : 0)
    }

    private func categoryTotals(for days: [DailySpend]) -> [(category: BudgetCategory, amount: Double)] {
        BudgetCategory.allCases.map { category in
            (category, days.reduce(0) { $0 + ($1.amounts[category] ?? 0) })
        }
    }

    var body: some View {
        Button {
            withAnimation(.spring(duration: 0.4, bounce: 0.2)) {
                mode = mode == .month ? .week : .month
                if mode == .week { scrollPosition = defaultWeekStart() }
            }
        } label: {
            GroupBox(label:
                HStack {
                    Label("Daily Spending", systemImage: "calendar.badge.clock")
                    Spacer()
                    if hasData { modeBadge }
                }
            ) {
                if hasData {
                    VStack(spacing: DesignSystem.Spacing.medium.rawValue) {
                        statsHeader
                        chart
                            .frame(height: 170)
                        dock
                            .id(selectedDate)
                            .transition(.opacity)
                    }
                    .animation(.easeInOut(duration: 0.25), value: selectedDate)
                } else {
                    emptyState
                }
            }
            .groupBoxStyle(TrenteGroupBoxStyle())
        }
        .buttonStyle(PressableCardButtonStyle())
        .sensoryFeedback(.selection, trigger: mode)
    }

    private var modeBadge: some View {
        Text(mode == .month ? "Month" : "Last 7 Days")
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Capsule().fill(.secondary.opacity(0.12)))
            .contentTransition(.opacity)
    }

    private var statsHeader: some View {
        let stats = totalAndAverage(for: visibleDays)
        return HStack(alignment: .firstTextBaseline) {
            Text(formattedAmount(stats.total))
                .font(.title2.bold())
                .contentTransition(.numericText(value: stats.total))
            Spacer()
            Text("\(formattedAmount(stats.average))/day avg")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var chart: some View {
        Chart {
            RuleMark(x: .value("Date", monthStartDay, unit: .day)).opacity(0)
            RuleMark(x: .value("Date", monthEndDay, unit: .day)).opacity(0)

            if let todayDate {
                RectangleMark(
                    x: .value("Date", todayDate, unit: .day),
                    yStart: .value("Min", 0),
                    yEnd: .value("Max", maxDailyTotal * 1.2)
                )
                .foregroundStyle(Color.primary.opacity(0.06))
                .cornerRadius(6)
            }

            ForEach(dailyData) { item in
                ForEach(BudgetCategory.allCases) { category in
                    if let amount = item.amounts[category] {
                        BarMark(
                            x: .value("Date", item.date, unit: .day),
                            y: .value("Amount", amount)
                        )
                        .foregroundStyle(category.color.gradient)
                        .cornerRadius(3)
                        .opacity(barOpacity(for: item.date))
                    }
                }
            }
        }
        .chartYScale(domain: 0...(maxDailyTotal * 1.2))
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: mode == .week ? 1 : 5)) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let date = value.as(Date.self) {
                        if mode == .week {
                            VStack(spacing: 1) {
                                Text(date, format: .dateTime.weekday(.abbreviated)).font(.caption2.bold())
                                Text(date, format: .dateTime.day()).font(.caption2).foregroundStyle(.secondary)
                            }
                        } else {
                            Text(date, format: .dateTime.day()).font(.caption2)
                        }
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { _ in AxisGridLine() }
        }
        .chartScrollableAxes(mode == .week ? .horizontal : [])
        .chartXVisibleDomain(
            length: mode == .week ? 60 * 60 * 24 * 7 : 60 * 60 * 24 * Double(daysInMonth)
        )
        .chartScrollPosition(x: $scrollPosition)
        .chartXSelection(value: $selectedDate)
        .animation(.spring(duration: 0.4, bounce: 0.15), value: mode)
    }

    private func barOpacity(for date: Date) -> Double {
        guard let selectedDate else { return 1 }
        return calendar.isDate(selectedDate, inSameDayAs: date) ? 1 : 0.3
    }

    @ViewBuilder
    private var dock: some View {
        if let selectedDate, let day = day(on: selectedDate) {
            dockContent(title: dayTitle(day.date), days: [day])
        } else {
            dockContent(
                title: mode == .month ? String(localized: "This Month") : String(localized: "This Week"),
                days: visibleDays
            )
        }
    }

    private func dayTitle(_ date: Date) -> String {
        date.formatted(.dateTime.weekday(.wide).day().month(.abbreviated))
    }

    @ViewBuilder
    private func dockContent(title: String, days: [DailySpend]) -> some View {
        let total = days.reduce(0) { $0 + $1.total }
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title).font(.caption.bold())
                Spacer()
                Text(formattedAmount(total)).font(.caption.bold())
            }
            proportionCapsule(for: days)
            proportionLegend(for: days)
        }
    }

    @ViewBuilder
    private func proportionCapsule(for days: [DailySpend]) -> some View {
        let totals = categoryTotals(for: days)
        let grandTotal = max(totals.reduce(0) { $0 + $1.amount }, 1)
        GeometryReader { geo in
            HStack(spacing: 3) {
                ForEach(totals, id: \.category) { entry in
                    if entry.amount > 0 {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(entry.category.color.gradient)
                            .frame(width: max(geo.size.width * (entry.amount / grandTotal) - 3, 3))
                    }
                }
            }
        }
        .frame(height: 10)
    }

    @ViewBuilder
    private func proportionLegend(for days: [DailySpend]) -> some View {
        let totals = categoryTotals(for: days)
        let grandTotal = max(totals.reduce(0) { $0 + $1.amount }, 1)
        HStack(spacing: DesignSystem.Spacing.medium.rawValue) {
            ForEach(totals, id: \.category) { entry in
                if entry.amount > 0 {
                    HStack(spacing: 4) {
                        Circle().fill(entry.category.color).frame(width: 6, height: 6)
                        Text("\(entry.category.shortName) \(Int((entry.amount / grandTotal) * 100))%")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            Spacer()
        }
    }

    private var emptyState: some View {
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

#Preview {
    DailySpendingCard(month: .month2)
        .padding()
}
