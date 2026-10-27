//
//  DailySpendingDock.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 27/10/2026.
//

import SwiftUI

struct DailySpendingDock: View {
    let title: String
    let days: [DailySpend]
    let currencyCode: String

    var body: some View {
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

    private func formattedAmount(_ value: Double) -> String {
        value.formatted(.currency(code: currencyCode).precision(.fractionLength(0)))
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
}

struct DailySpendingEmptyState: View {
    var body: some View {
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
