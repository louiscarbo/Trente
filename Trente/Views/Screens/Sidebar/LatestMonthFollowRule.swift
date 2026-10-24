//
//  LatestMonthFollowRule.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 24/10/2026.
//

import Foundation

enum LatestMonthFollowRule {
    static func shouldSelectLatestMonth(
        selectedMonthID: UUID?,
        isShowingOtherScreen: Bool,
        previousLatestMonthID: UUID?,
        remainingMonthIDs: Set<UUID>
    ) -> Bool {
        guard !isShowingOtherScreen else { return false }
        guard let selectedMonthID else { return true }
        return selectedMonthID == previousLatestMonthID || !remainingMonthIDs.contains(selectedMonthID)
    }
}
