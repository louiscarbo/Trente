//
//  OnboardingModel.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 23/10/2026.
//

import Foundation
import Observation

enum OnboardingDirection {
    case forward
    case backward
}

@MainActor
@Observable
final class OnboardingModel {
    let steps: [OnboardingStep]
    private(set) var currentStep: OnboardingStep
    private(set) var direction: OnboardingDirection = .forward
    var draft: MonthDraft

    init(
        steps: [OnboardingStep],
        locale: Locale = .current,
        startDate: Date = .now
    ) {
        self.steps = steps
        self.currentStep = steps.first ?? .welcome
        self.draft = Self.defaultDraft(locale: locale, startDate: startDate)
    }

    var canGoBack: Bool {
        currentIndex > 0
    }

    var isLastStep: Bool {
        currentIndex == steps.count - 1
    }

    func goForward() {
        guard !isLastStep else { return }
        direction = .forward
        currentStep = steps[currentIndex + 1]
    }

    func goBack() {
        guard canGoBack else { return }
        direction = .backward
        currentStep = steps[currentIndex - 1]
    }

    private var currentIndex: Int {
        steps.firstIndex(of: currentStep) ?? 0
    }

    static func defaultDraft(locale: Locale, startDate: Date) -> MonthDraft {
        MonthDraft(
            startDate: startDate,
            currency: defaultCurrency(for: locale),
            idealBudgetCents: 0,
            idealRepartition: Dictionary(uniqueKeysWithValues: BudgetCategory.allCases.map { ($0, 0) })
        )
    }

    static func defaultCurrency(for locale: Locale) -> Currency {
        locale.currency
            .flatMap { Currencies.currency(for: $0.identifier) }
            ?? Currencies.currency(for: "EUR")!
    }
}
