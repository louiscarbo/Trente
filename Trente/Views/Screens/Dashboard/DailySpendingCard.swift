//
//  DailySpendingCard.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 16/05/2026.
//

import SwiftUI
import Charts

struct DailySpendingCard: View {
    let spending: DailySpending
    let currencyCode: String

    @State private var mode: SpendingWindowMode = .month
    @State private var scrollPosition: Date
    @State private var settledScrollPosition: Date
    @State private var settleTask: Task<Void, Never>?
    @State private var selectedDate: Date?

    init(spending: DailySpending, currencyCode: String) {
        self.spending = spending
        self.currencyCode = currencyCode
        let defaultWeekStart = spending.defaultWeekStart
        self._scrollPosition = State(initialValue: defaultWeekStart)
        self._settledScrollPosition = State(initialValue: defaultWeekStart)
    }

    private enum SpendingWindowMode: Hashable {
        case month, week
    }

    private func yAxisMax(for spending: DailySpending) -> Double {
        let windowPosition = mode == .week ? settledScrollPosition : nil
        return max(spending.maxTotal(inWindowAt: windowPosition), 1) * 1.2
    }

    private func visibleDays(in spending: DailySpending) -> [DailySpend] {
        switch mode {
        case .month:
            return spending.days
        case .week:
            return spending.days(inWindowAt: scrollPosition)
        }
    }

    private func selectedDay(in spending: DailySpending) -> DailySpend? {
        selectedDate.flatMap(spending.day(on:))
    }

    var body: some View {
        let hasData = !spending.days.isEmpty
        let selectedDay = selectedDay(in: spending)

        Button {
            withAnimation(.spring(duration: 0.4, bounce: 0.2)) {
                mode = mode == .month ? .week : .month
                if mode == .week { scrollPosition = spending.defaultWeekStart }
                settledScrollPosition = scrollPosition
            }
        } label: {
            GroupBox(label:
                HStack {
                    cardTitle(spending, hasData: hasData)
                    Spacer()
                    if hasData { switchHint }
                }
            ) {
                if hasData {
                    VStack(spacing: DesignSystem.Spacing.medium.rawValue) {
                        chart(spending, selectedDay: selectedDay)
                            .frame(height: 210)
                        dock(spending, selectedDay: selectedDay)
                            .id(selectedDay?.date)
                            .transition(.opacity)
                    }
                    .animation(.easeInOut(duration: 0.25), value: selectedDay?.date)
                } else {
                    DailySpendingEmptyState()
                }
            }
            .groupBoxStyle(TrenteGroupBoxStyle())
        }
        .buttonStyle(PressableCardButtonStyle())
        .sensoryFeedback(.selection, trigger: mode)
        .sensoryFeedback(trigger: selectedDay?.date) { _, newDate in
            newDate == nil ? nil : .selection
        }
    }

    private func periodTitle(_ spending: DailySpending) -> String {
        let calendar = Calendar.current
        switch mode {
        case .month:
            if spending.today != nil { return String(localized: "This Month") }
            let isCurrentYear = calendar.isDate(.now, equalTo: spending.monthStartDay, toGranularity: .year)
            return isCurrentYear
                ? spending.monthStartDay.formatted(.dateTime.month(.wide))
                : spending.monthStartDay.formatted(.dateTime.month(.wide).year())
        case .week:
            let window = spending.weekWindow(at: scrollPosition)
            if let today = spending.today, calendar.isDate(window.upperBound, inSameDayAs: today) {
                return String(localized: "Last 7 Days")
            }
            return (window.lowerBound..<window.upperBound).formatted(.interval.month(.abbreviated).day())
        }
    }

    private func cardTitle(_ spending: DailySpending, hasData: Bool) -> some View {
        let title = hasData ? periodTitle(spending) : String(localized: "Daily Spending")
        return Label(title, systemImage: "calendar.badge.clock")
            .contentTransition(.opacity)
            .animation(.easeInOut(duration: 0.2), value: title)
    }

    private var switchHint: some View {
        Image(systemName: "chevron.up.chevron.down")
            .font(.caption.bold())
            .foregroundStyle(.secondary)
    }

    private func chart(_ spending: DailySpending, selectedDay: DailySpend?) -> some View {
        let yAxisMax = yAxisMax(for: spending)
        let visibleDaysCount = mode == .week ? DailySpending.weekLengthInDays : spending.daysInMonth
        return Chart {
            RuleMark(x: .value("Date", spending.monthStartDay, unit: .day)).opacity(0)
            RuleMark(x: .value("Date", spending.monthEndDay, unit: .day)).opacity(0)

            if let today = spending.today {
                RectangleMark(
                    x: .value("Date", today, unit: .day),
                    yStart: .value("Min", 0),
                    yEnd: .value("Max", yAxisMax)
                )
                .foregroundStyle(Color.primary.opacity(0.06))
                .cornerRadius(6)
            }

            ForEach(spending.days) { item in
                ForEach(BudgetCategory.allCases) { category in
                    if let amount = item.amounts[category] {
                        BarMark(
                            x: .value("Date", item.date, unit: .day),
                            y: .value("Amount", amount)
                        )
                        .foregroundStyle(category.color.gradient)
                        .cornerRadius(3)
                        .opacity(barOpacity(for: item.date, selectedDay: selectedDay))
                    }
                }
            }
        }
        .chartYScale(domain: 0...yAxisMax)
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
        .chartScrollTargetBehavior(.valueAligned(matching: DateComponents(hour: 0)))
        .chartXVisibleDomain(length: 60 * 60 * 24 * Double(visibleDaysCount))
        .chartScrollPosition(x: $scrollPosition)
        .chartXSelection(value: $selectedDate)
        .onChange(of: scrollPosition) { scheduleSettle() }
        .animation(.spring(duration: 0.4, bounce: 0.15), value: mode)
        .animation(.easeInOut(duration: 0.3), value: yAxisMax)
    }

    private func scheduleSettle() {
        settleTask?.cancel()
        settleTask = Task {
            try? await Task.sleep(for: .milliseconds(150))
            guard !Task.isCancelled else { return }
            settledScrollPosition = scrollPosition
        }
    }

    private func barOpacity(for date: Date, selectedDay: DailySpend?) -> Double {
        guard let selectedDay else { return 1 }
        return selectedDay.date == date ? 1 : 0.3
    }

    @ViewBuilder
    private func dock(_ spending: DailySpending, selectedDay: DailySpend?) -> some View {
        if let selectedDay {
            DailySpendingDock(
                title: selectedDay.date.formatted(.dateTime.weekday(.wide).day().month(.abbreviated)),
                days: [selectedDay],
                currencyCode: currencyCode
            )
        } else {
            DailySpendingDock(
                title: String(localized: "Total"),
                days: visibleDays(in: spending),
                currencyCode: currencyCode
            )
        }
    }
}

#Preview {
    DailySpendingCard(spending: DailySpending(month: .month2), currencyCode: Month.month2.currency.isoCode)
        .padding()
}
