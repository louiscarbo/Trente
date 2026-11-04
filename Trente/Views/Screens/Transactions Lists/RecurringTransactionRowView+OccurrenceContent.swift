//
//  RecurringTransactionRowView+OccurrenceContent.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 20/04/2025.
//

import SwiftData
import SwiftUI

extension RecurringTransactionRowView {
    struct OccurrenceContent: View {
        let title: String
        let date: Date
        let categoryName: String
        let frequency: RecurrenceFrequency
        let amount: Double
        let currencyCode: String
        let isOverdue: Bool
        let isDueToday: Bool
        var showsDateBadge = true

        var body: some View {
            HStack(spacing: 12) {
                if showsDateBadge {
                    DateBadge(date: date, isOverdue: isOverdue)
                }
                VStack(alignment: .leading) {
                    Text(title)
                        .multilineTextAlignment(.leading)
                        .font(.headline)
                    subtitle
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(amount, format: .amount(currencyCode))
                    .font(.title2)
            }
        }

        private var subtitle: Text {
            if isOverdue {
                return Text("\(Text("Overdue").foregroundStyle(.orange)) · \(categoryName)")
            }
            if isDueToday {
                return Text("\(Text("Due today").foregroundStyle(Color.primary)) · \(categoryName)")
            }
            return Text("\(categoryName) · \(frequency.displayName)")
        }
    }
}
