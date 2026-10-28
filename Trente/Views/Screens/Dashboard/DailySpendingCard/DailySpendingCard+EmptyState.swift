//
//  DailySpendingCard+EmptyState.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 27/10/2026.
//

import SwiftUI

extension DailySpendingCard {
    struct EmptyState: View {
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
}
