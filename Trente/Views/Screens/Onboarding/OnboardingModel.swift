//
//  OnboardingModel.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 23/10/2026.
//

import Foundation
import Observation
import SwiftData

enum OnboardingDirection {
    case forward
    case backward
}

@MainActor
@Observable
final class OnboardingModel {
    static let suggestedPercentages: [BudgetCategory: Int] = [.needs: 50, .wants: 30, .savingsAndDebts: 20]

    let steps: [OnboardingStep]
    private(set) var currentStep: OnboardingStep
    private(set) var direction: OnboardingDirection = .forward
    private(set) var savedMonth: Month?
    private(set) var hasAddedIncome = false
    var draft: MonthDraft
    var isRepartitionComplete = false

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

    var canContinue: Bool {
        switch currentStep {
        case .budget:
            draft.idealBudgetCents > 0
        case .split:
            isRepartitionComplete
        case .welcome, .notifications, .applePay, .allSet:
            true
        }
    }

    var budgetCents: Int {
        get { draft.idealBudgetCents }
        set {
            let isSplitUntouched = draft.idealRepartition == Self.suggestedRepartition(for: draft.idealBudgetCents)
            let allocatedCents = draft.idealRepartition.values.reduce(0, +)
            draft.idealBudgetCents = newValue
            if isSplitUntouched || allocatedCents > newValue {
                draft.idealRepartition = Self.suggestedRepartition(for: newValue)
            }
        }
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

    func saveMonth(in context: ModelContext, reusingExistingMonth: Bool = false) throws {
        if savedMonth == nil, reusingExistingMonth {
            savedMonth = try MonthService.shared.latestMonth(in: context)
        }
        if let savedMonth {
            draft.apply(to: savedMonth)
            try context.save()
        } else {
            let month = draft.makeMonth()
            try MonthService.shared.create(month: month, in: context)
            savedMonth = month
        }
    }

    func addIncome(in context: ModelContext, now: Date = .now) throws {
        guard !hasAddedIncome, let month = savedMonth else { return }
        let repartition = month.idealRepartition.filter { $0.value > 0 }
        guard !repartition.isEmpty else { return }

        let monthStartDate = month.dateInterval.start
        let rule = RecurringTransactionRule(
            title: String(localized: "Income"),
            frequency: .monthly,
            startDate: Self.incomeStartDate(afterMonthStartingOn: monthStartDate, today: now),
            repartition: repartition,
            createdAt: now
        )
        context.insert(rule)
        RecurringTransactionService.shared.insertTransaction(
            for: RecurringTransactionOccurrence(rule: rule, date: monthStartDate, month: month),
            in: context,
            addedDate: monthStartDate
        )
        do {
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
        hasAddedIncome = true
    }

    private var currentIndex: Int {
        steps.firstIndex(of: currentStep) ?? 0
    }

    static func incomeStartDate(
        afterMonthStartingOn monthStartDate: Date,
        today: Date,
        calendar: Calendar = .current
    ) -> Date {
        let earliestDate = calendar.startOfDay(for: today)
        var startDate = calendar.startOfDay(for: monthStartDate)
        repeat {
            guard let nextStartDate = calendar.date(byAdding: .month, value: 1, to: startDate) else { break }
            startDate = nextStartDate
        } while startDate < earliestDate
        return startDate
    }

    static func defaultDraft(locale: Locale, startDate: Date) -> MonthDraft {
        MonthDraft(
            startDate: startDate,
            currency: defaultCurrency(for: locale),
            idealBudgetCents: 0,
            idealRepartition: suggestedRepartition(for: 0)
        )
    }

    static func defaultCurrency(for locale: Locale) -> Currency {
        locale.currency
            .flatMap { Currencies.currency(for: $0.identifier) }
            ?? Currencies.currency(for: "EUR")!
    }

    static func suggestedRepartition(for budgetCents: Int) -> [BudgetCategory: Int] {
        let needsCents = roundedDownToWholeUnits(budgetCents * suggestedPercentages[.needs, default: 0] / 100)
        let wantsCents = roundedDownToWholeUnits(budgetCents * suggestedPercentages[.wants, default: 0] / 100)
        return [
            .needs: needsCents,
            .wants: wantsCents,
            .savingsAndDebts: budgetCents - needsCents - wantsCents
        ]
    }

    private static func roundedDownToWholeUnits(_ cents: Int) -> Int {
        (cents / 100) * 100
    }
}
