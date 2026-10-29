//
//  DailySpendingCard+ChartDescriptor.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 29/10/2026.
//

import Accessibility
import SwiftUI

extension DailySpendingCard {
    struct ChartDescriptor: AXChartDescriptorRepresentable {
        let days: [DailySpend]
        let currencyCode: String

        func makeChartDescriptor() -> AXChartDescriptor {
            let currencyCode = currencyCode
            let xAxis = AXCategoricalDataAxisDescriptor(
                title: String(localized: "Day"),
                categoryOrder: days.map(dayName)
            )
            let yAxis = AXNumericDataAxisDescriptor(
                title: String(localized: "Amount"),
                range: 0...max(days.map(\.total).max() ?? 0, 1),
                gridlinePositions: []
            ) { amount in
                amount.formatted(.budget(currencyCode))
            }
            let series = BudgetCategory.allCases.map { category in
                AXDataSeriesDescriptor(
                    name: category.name,
                    isContinuous: false,
                    dataPoints: days.map { day in
                        AXDataPoint(x: dayName(of: day), y: day.amounts[category] ?? 0)
                    }
                )
            }
            return AXChartDescriptor(
                title: String(localized: "Daily Spending"),
                summary: nil,
                xAxis: xAxis,
                yAxis: yAxis,
                additionalAxes: [],
                series: series
            )
        }

        private func dayName(of day: DailySpend) -> String {
            day.date.formatted(.dateTime.day().month(.abbreviated))
        }
    }
}
