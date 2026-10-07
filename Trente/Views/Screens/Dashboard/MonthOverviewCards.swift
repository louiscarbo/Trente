//
//  MonthOverviewCards.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 16/05/2026.
//

import SwiftUI
import Charts

// MARK: - Daily Spending Card

struct DailySpendingCard: View {
    @State var month: Month

    @State private var mode: SpendingWindowMode = .month
    @State private var scrollPosition: Date
    @State private var settledScrollPosition: Date
    @State private var settleTask: Task<Void, Never>?
    @State private var selectedDate: Date?

    init(month: Month) {
        self._month = State(initialValue: month)
        let defaultWeekStart = DailySpending(month: month).defaultWeekStart
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

    private func formattedAmount(_ value: Double) -> String {
        value.formatted(.currency(code: month.currency.isoCode).precision(.fractionLength(0)))
    }

    var body: some View {
        let spending = DailySpending(month: month)
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
                    emptyState
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
            let isCurrentYear = calendar.isDate(Date(), equalTo: month.startDate, toGranularity: .year)
            return isCurrentYear
                ? month.startDate.formatted(.dateTime.month(.wide))
                : month.startDate.formatted(.dateTime.month(.wide).year())
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
            dockContent(title: dayTitle(selectedDay.date), days: [selectedDay])
        } else {
            dockContent(title: String(localized: "Total"), days: visibleDays(in: spending))
        }
    }

    private func dayTitle(_ date: Date) -> String {
        date.formatted(.dateTime.weekday(.wide).day().month(.abbreviated))
    }

    @ViewBuilder
    private func dockContent(title: String, days: [DailySpend]) -> some View {
        let slices = CategorySlice.slices(for: days)
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title).font(.caption.bold())
                Spacer()
                Text(formattedAmount(days.reduce(0) { $0 + $1.total })).font(.caption.bold())
            }
            proportionCapsule(for: slices)
            proportionLegend(for: slices)
        }
    }

    private func proportionCapsule(for slices: [CategorySlice]) -> some View {
        GeometryReader { geo in
            HStack(spacing: 3) {
                ForEach(slices, id: \.category) { slice in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(slice.category.color.gradient)
                        .frame(width: max(geo.size.width * slice.share - 3, 3))
                }
            }
        }
        .frame(height: 10)
    }

    private func proportionLegend(for slices: [CategorySlice]) -> some View {
        HStack(alignment: .top, spacing: DesignSystem.Spacing.medium.rawValue) {
            ForEach(slices, id: \.category) { slice in
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Circle().fill(slice.category.color).frame(width: 6, height: 6)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(slice.category.shortName)
                            .font(.caption2.bold())
                        Text("\(formattedAmount(slice.amount)) · \(slice.percent)%")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
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
