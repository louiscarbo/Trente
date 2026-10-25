//
//  ReviewPrompt.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 24/10/2026.
//

import SwiftUI
import StoreKit

private struct ReviewPromptTrigger: Equatable {
    let monthCount: Int
    let isCalm: Bool
}

private struct ReviewPromptModifier: ViewModifier {
    let monthCount: Int
    let isShowingLatestMonth: Bool
    let isPresentingSheet: Bool

    @Environment(\.requestReview) private var requestReview
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage(ReviewRequestPolicy.Keys.lastRequestedVersion) private var lastRequestedVersion = ""
    @AppStorage(ReviewRequestPolicy.Keys.lastRequestedMonthCount) private var lastRequestedMonthCount = 0
    @AppStorage(ReviewRequestPolicy.Keys.firstUseTimestamp) private var firstUseTimestamp: Double = 0

    private var isCalm: Bool {
        scenePhase == .active && isShowingLatestMonth && !isPresentingSheet
    }

    func body(content: Content) -> some View {
        content
            .onAppear(perform: recordFirstUse)
            .task(id: ReviewPromptTrigger(monthCount: monthCount, isCalm: isCalm)) {
                await requestReviewIfAppropriate()
            }
    }

    private func recordFirstUse() {
        guard firstUseTimestamp == 0 else { return }
        firstUseTimestamp = Date.now.timeIntervalSinceReferenceDate
    }

    private func requestReviewIfAppropriate() async {
        guard isCalm else { return }
        do {
            try await Task.sleep(for: ReviewRequestPolicy.delay)
        } catch {
            return
        }
        let currentVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
        let shouldRequest = ReviewRequestPolicy.shouldRequest(
            monthCount: monthCount,
            lastRequestedMonthCount: lastRequestedMonthCount,
            lastRequestedVersion: lastRequestedVersion,
            currentVersion: currentVersion,
            firstUseDate: firstUseTimestamp == 0 ? nil : Date(timeIntervalSinceReferenceDate: firstUseTimestamp),
            now: .now
        )
        guard shouldRequest else { return }
        lastRequestedVersion = currentVersion
        lastRequestedMonthCount = monthCount
        requestReview()
    }
}

extension View {
    func reviewPrompt(
        monthCount: Int,
        isShowingLatestMonth: Bool,
        isPresentingSheet: Bool
    ) -> some View {
        modifier(
            ReviewPromptModifier(
                monthCount: monthCount,
                isShowingLatestMonth: isShowingLatestMonth,
                isPresentingSheet: isPresentingSheet
            )
        )
    }
}
