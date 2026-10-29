//
//  SplitStepView+AdaptiveCategoryLegend.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 23/10/2026.
//

import SwiftUI

extension SplitStepView {
    struct AdaptiveCategoryLegend: View {
        let isInPrimaryColumn: Bool

        @Environment(\.isOnboardingLayoutRegular) private var isRegular

        var body: some View {
            if isRegular == isInPrimaryColumn {
                CategoryLegend()
            }
        }
    }
}
