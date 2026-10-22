//
//  OnboardingModelTests.swift
//  TrenteTests
//
//  Created by Louis Carbo Estaque on 23/10/2026.
//

import Testing
import Foundation
@testable import Trente

@MainActor
struct OnboardingModelTests {

    @Test("The default draft uses the locale's currency, today and an empty budget")
    func defaultDraft() {
        let today = Date.now
        let model = OnboardingModel(steps: OnboardingStep.allCases, locale: Locale(identifier: "en_US"), startDate: today)

        #expect(model.draft.currency.isoCode == "USD")
        #expect(model.draft.startDate == today)
        #expect(model.draft.idealBudgetCents == 0)
        #expect(model.draft.idealRepartition.values.allSatisfy { $0 == 0 })
    }

    @Test("The default currency falls back to euros when the locale's currency is unsupported")
    func defaultCurrencyFallback() {
        let currency = OnboardingModel.defaultCurrency(for: Locale(identifier: "ar_EG"))

        #expect(currency.isoCode == "EUR")
    }

    @Test("Moving forward and back follows the step list and stops at both ends")
    func navigation() {
        let model = OnboardingModel(steps: [.welcome, .budget, .allSet])

        #expect(model.currentStep == .welcome)
        #expect(!model.canGoBack)

        model.goBack()
        #expect(model.currentStep == .welcome)

        model.goForward()
        #expect(model.currentStep == .budget)
        #expect(model.direction == .forward)

        model.goForward()
        #expect(model.currentStep == .allSet)
        #expect(model.isLastStep)

        model.goForward()
        #expect(model.currentStep == .allSet)

        model.goBack()
        #expect(model.currentStep == .budget)
        #expect(model.direction == .backward)
    }

    @Test(
        "The gate shows onboarding only without a completed flag and without months, unless forced",
        arguments: [
            (false, 0, false, true),
            (true, 0, false, false),
            (false, 1, false, false),
            (true, 3, false, false),
            (true, 3, true, true)
        ]
    )
    func gate(hasCompletedOnboarding: Bool, monthCount: Int, isForced: Bool, expected: Bool) {
        let shouldShow = OnboardingGate.shouldShow(
            hasCompletedOnboarding: hasCompletedOnboarding,
            monthCount: monthCount,
            isForced: isForced
        )

        #expect(shouldShow == expected)
    }
}
