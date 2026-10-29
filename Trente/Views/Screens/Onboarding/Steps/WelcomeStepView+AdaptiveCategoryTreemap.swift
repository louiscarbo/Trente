//
//  WelcomeStepView+AdaptiveCategoryTreemap.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 23/10/2026.
//

import SwiftUI

extension WelcomeStepView {
    struct AdaptiveCategoryTreemap: View {
        let percentages: [BudgetCategory: Int]

        @Environment(\.isOnboardingLayoutRegular) private var isRegular

        var body: some View {
            CategoryTreemap(percentages: percentages, isWide: isRegular)
        }
    }
}
