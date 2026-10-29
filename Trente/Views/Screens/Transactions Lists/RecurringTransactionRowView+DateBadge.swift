//
//  RecurringTransactionRowView+DateBadge.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 20/04/2025.
//

import SwiftData
import SwiftUI

extension RecurringTransactionRowView {
    struct DateBadge: View {
        let date: Date
        let isOverdue: Bool

        var body: some View {
            VStack(spacing: 0) {
                Text(date, format: .dateTime.day())
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(isOverdue ? Color.orange : Color.primary)
                Text(date, format: .dateTime.month(.abbreviated))
                    .font(.caption2)
                    .textCase(.uppercase)
                    .foregroundStyle(isOverdue ? Color.orange : Color.secondary)
            }
            .frame(width: 36)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(date, format: .dateTime.day().month(.wide)))
        }
    }
}
