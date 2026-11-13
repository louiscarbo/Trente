//
//  MonthView+RemainingLine.swift
//  Trente
//

import SwiftUI

extension MonthView {
    struct RemainingLine: View {
        let remaining: Double
        let income: Double
        let currencyCode: String

        var body: some View {
            if income > 0 {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(remaining, format: .budget(currencyCode)) left")
                        .font(.title3.bold())
                        .foregroundStyle(remaining < 0 ? .red : .green)
                    Text(verbatim: "·")
                        .foregroundStyle(.secondary)
                    Text("of \(income, format: .budget(currencyCode))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .combine)
            }
        }
    }
}

#Preview("Remaining line", traits: .sizeThatFitsLayout) {
    VStack(spacing: 20) {
        MonthView.RemainingLine(remaining: 3000, income: 3000, currencyCode: "USD")
        MonthView.RemainingLine(remaining: 1650, income: 3000, currencyCode: "USD")
        MonthView.RemainingLine(remaining: -120, income: 3000, currencyCode: "USD")
        MonthView.RemainingLine(remaining: 0, income: 0, currencyCode: "USD")
    }
    .padding()
}
