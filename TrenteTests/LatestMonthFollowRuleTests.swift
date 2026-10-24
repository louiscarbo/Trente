//
//  LatestMonthFollowRuleTests.swift
//  TrenteTests
//
//  Created by Louis Carbo Estaque on 24/10/2026.
//

import Foundation
import Testing
@testable import Trente

struct LatestMonthFollowRuleTests {
    private let october = UUID()
    private let september = UUID()
    private let november = UUID()

    @Test("On the previous current month, the app moves to the new month")
    func followsFromPreviousLatest() {
        #expect(LatestMonthFollowRule.shouldSelectLatestMonth(
            selectedMonthID: october,
            isShowingOtherScreen: false,
            previousLatestMonthID: october,
            remainingMonthIDs: [september, october, november]
        ))
    }

    @Test("On an older month, the app stays there")
    func staysOnOlderMonth() {
        #expect(!LatestMonthFollowRule.shouldSelectLatestMonth(
            selectedMonthID: september,
            isShowingOtherScreen: false,
            previousLatestMonthID: october,
            remainingMonthIDs: [september, october, november]
        ))
    }

    @Test("On the recurring transactions screen, the app stays there")
    func staysOnOtherScreen() {
        #expect(!LatestMonthFollowRule.shouldSelectLatestMonth(
            selectedMonthID: nil,
            isShowingOtherScreen: true,
            previousLatestMonthID: october,
            remainingMonthIDs: [september, october, november]
        ))
    }

    @Test("When the open month was deleted, the app moves to the latest month")
    func followsWhenSelectedMonthIsDeleted() {
        #expect(LatestMonthFollowRule.shouldSelectLatestMonth(
            selectedMonthID: september,
            isShowingOtherScreen: false,
            previousLatestMonthID: october,
            remainingMonthIDs: [october]
        ))
    }

    @Test("With nothing open, the app opens the latest month")
    func followsWhenNothingIsSelected() {
        #expect(LatestMonthFollowRule.shouldSelectLatestMonth(
            selectedMonthID: nil,
            isShowingOtherScreen: false,
            previousLatestMonthID: nil,
            remainingMonthIDs: [october]
        ))
    }
}
