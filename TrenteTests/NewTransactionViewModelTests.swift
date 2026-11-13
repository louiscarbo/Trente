//
//  NewTransactionViewModelTests.swift
//  TrenteTests
//
//  Created by Louis Carbo Estaque on 25/10/2026.
//

import Testing
import SwiftData
import Foundation
@testable import Trente

@MainActor
@Suite(.serialized)
struct NewTransactionViewModelTests {
    private func rentViewModel(isRecurrent: Bool, center: FakeNotificationCenter) -> NewTransactionViewModel {
        let viewModel = NewTransactionViewModel(permissionService: NotificationPermissionService(center: center))
        viewModel.request.title = "Rent"
        viewModel.request.amountCents = -800_00
        viewModel.request.selectedCategory = .needs
        viewModel.request.isRecurrent = isRecurrent
        return viewModel
    }

    @Test("Only a recurring transaction asks for notifications", arguments: [true, false])
    func asksForNotificationsOnlyWhenRecurring(isRecurrent: Bool) async throws {
        let context = try makeContext()
        let today = Calendar.current.dateComponents([.year, .month], from: .now)
        let month = insertMonth(year: today.year!, month: today.month!, in: context)
        let center = FakeNotificationCenter(status: .notDetermined, grants: true)
        let viewModel = rentViewModel(isRecurrent: isRecurrent, center: center)

        #expect(viewModel.createTransaction(for: month, in: context))
        await viewModel.permissionRequest?.value

        #expect(await center.requestCount == (isRecurrent ? 1 : 0))
    }

    @Test("An expense needs an amount and a category to advance")
    func expenseNeedsAmountAndCategory() {
        let viewModel = NewTransactionViewModel()
        viewModel.request.type = .expense
        #expect(!viewModel.canAdvance)

        viewModel.request.amountCents = -12_00
        #expect(!viewModel.canAdvance)

        viewModel.request.selectedCategory = .wants
        #expect(viewModel.canAdvance)

        viewModel.request.amountCents = 0
        #expect(!viewModel.canAdvance)
    }

    @Test("An income advances with an amount and no category")
    func incomeNeedsOnlyAmount() {
        let viewModel = NewTransactionViewModel()
        viewModel.request.type = .income
        #expect(!viewModel.canAdvance)

        viewModel.request.amountCents = 1_500_00
        #expect(viewModel.canAdvance)
    }

    @Test("The title step needs a title")
    func titleStepNeedsTitle() {
        let viewModel = NewTransactionViewModel()
        viewModel.step = .title
        #expect(!viewModel.canAdvance)

        viewModel.request.title = "Groceries"
        #expect(viewModel.canAdvance)
    }

    @Test("An income is split right after its title")
    func incomeSplitComesAfterTitle() {
        let viewModel = NewTransactionViewModel()
        viewModel.request.type = .income
        viewModel.request.isRecurrent = true

        #expect(viewModel.filteredSteps == [.amountCategory, .title, .repartition, .notesImage, .recurrence])
    }

    @Test("The repartition step needs a complete split")
    func repartitionStepNeedsCompleteSplit() {
        let viewModel = NewTransactionViewModel()
        viewModel.step = .repartition
        #expect(!viewModel.canAdvance)

        viewModel.isRepartitionComplete = true
        #expect(viewModel.canAdvance)
    }

    @Test("The notes and recurrence steps can always advance", arguments: [NewTransactionStep.notesImage, .recurrence])
    func optionalStepsAlwaysAdvance(step: NewTransactionStep) {
        let viewModel = NewTransactionViewModel()
        viewModel.step = step
        #expect(viewModel.canAdvance)
    }

    private func incomeAtTitleStep(amountCents: Int) -> NewTransactionViewModel {
        let viewModel = NewTransactionViewModel()
        viewModel.request.type = .income
        viewModel.request.amountCents = amountCents
        viewModel.step = .title
        return viewModel
    }

    @Test("Entering the split step the first time starts every category at zero")
    func splitStartsAtZero() {
        let viewModel = incomeAtTitleStep(amountCents: 1_000_00)

        viewModel.nextStep()

        #expect(viewModel.step == .repartition)
        #expect(viewModel.request.repartition == [.needs: 0, .wants: 0, .savingsAndDebts: 0])
    }

    @Test("The split survives going back and forth")
    func splitSurvivesBackAndNext() {
        let viewModel = incomeAtTitleStep(amountCents: 1_000_00)
        viewModel.nextStep()
        viewModel.request.repartition = [.needs: 500_00, .wants: 200_00, .savingsAndDebts: 0]

        viewModel.previousStep()
        viewModel.nextStep()

        #expect(viewModel.request.repartition == [.needs: 500_00, .wants: 200_00, .savingsAndDebts: 0])
    }

    @Test("The split starts over when the amount changed")
    func splitResetsWhenAmountChanged() {
        let viewModel = incomeAtTitleStep(amountCents: 1_000_00)
        viewModel.nextStep()
        viewModel.request.repartition = [.needs: 1_000_00, .wants: 0, .savingsAndDebts: 0]

        viewModel.previousStep()
        viewModel.request.amountCents = 1_200_00
        viewModel.nextStep()

        #expect(viewModel.request.repartition == [.needs: 0, .wants: 0, .savingsAndDebts: 0])
    }

    private func month(repartition: [BudgetCategory: Int]) -> Month {
        Month(
            startDate: Calendar.current.date(from: DateComponents(year: 2026, month: 12, day: 1))!,
            currency: Currencies.currency(for: "EUR")!,
            idealBudgetCents: 3000_00,
            idealRepartition: repartition
        )
    }

    private func incomeAtTitleStep(amountCents: Int, month: Month) -> NewTransactionViewModel {
        let viewModel = incomeAtTitleStep(amountCents: amountCents)
        viewModel.setMonth(month)
        return viewModel
    }

    @Test("An income is pre-split like the month it is added to")
    func splitStartsFromTheMonthsSplit() {
        let viewModel = incomeAtTitleStep(
            amountCents: 1_000_00,
            month: month(repartition: [.needs: 900_00, .wants: 1200_00, .savingsAndDebts: 900_00])
        )

        viewModel.nextStep()

        #expect(viewModel.request.repartition == [.needs: 300_00, .wants: 400_00, .savingsAndDebts: 300_00])
        #expect(viewModel.prefilledMonthName != nil)
    }

    @Test("The pre-filled split adds up to the income even with odd cents")
    func prefilledSplitAddsUp() {
        let viewModel = incomeAtTitleStep(
            amountCents: 1_000_01,
            month: month(repartition: [.needs: 50, .wants: 30, .savingsAndDebts: 20])
        )

        viewModel.nextStep()

        #expect(viewModel.request.repartition.values.reduce(0, +) == 1_000_01)
    }

    @Test("A month with no split of its own opens at zero without a note")
    func monthWithoutSplitOpensAtZero() {
        let viewModel = incomeAtTitleStep(
            amountCents: 1_000_00,
            month: month(repartition: [.needs: 0, .wants: 0, .savingsAndDebts: 0])
        )

        viewModel.nextStep()

        #expect(viewModel.request.repartition == [.needs: 0, .wants: 0, .savingsAndDebts: 0])
        #expect(viewModel.prefilledMonthName == nil)
    }

    @Test("Manual edits to the pre-filled split survive going back and forth")
    func editsToThePrefilledSplitSurvive() {
        let viewModel = incomeAtTitleStep(
            amountCents: 1_000_00,
            month: month(repartition: [.needs: 50, .wants: 30, .savingsAndDebts: 20])
        )
        viewModel.nextStep()
        viewModel.request.repartition = [.needs: 700_00, .wants: 200_00, .savingsAndDebts: 100_00]

        viewModel.previousStep()
        viewModel.nextStep()

        #expect(viewModel.request.repartition == [.needs: 700_00, .wants: 200_00, .savingsAndDebts: 100_00])
    }

    @Test("Changing the amount applies the month's split to the new amount")
    func prefilledSplitFollowsTheNewAmount() {
        let viewModel = incomeAtTitleStep(
            amountCents: 1_000_00,
            month: month(repartition: [.needs: 50, .wants: 30, .savingsAndDebts: 20])
        )
        viewModel.nextStep()
        viewModel.request.repartition = [.needs: 1_000_00, .wants: 0, .savingsAndDebts: 0]

        viewModel.previousStep()
        viewModel.request.amountCents = 2_000_00
        viewModel.nextStep()

        #expect(viewModel.request.repartition == [.needs: 1_000_00, .wants: 600_00, .savingsAndDebts: 400_00])
    }

    @Test("A recurring income gets the same pre-filled split")
    func recurringIncomeIsPrefilledToo() {
        let viewModel = incomeAtTitleStep(
            amountCents: 1_000_00,
            month: month(repartition: [.needs: 50, .wants: 30, .savingsAndDebts: 20])
        )
        viewModel.request.isRecurrent = true

        viewModel.nextStep()

        #expect(viewModel.request.repartition == [.needs: 500_00, .wants: 300_00, .savingsAndDebts: 200_00])
    }

    @Test("A picked photo still lands after leaving its step")
    func photoSurvivesLeavingTheStep() async {
        let viewModel = NewTransactionViewModel()
        viewModel.request.isRecurrent = true
        viewModel.step = .notesImage
        let (gate, release) = AsyncStream.makeStream(of: Void.self)

        viewModel.loadImage {
            for await _ in gate { break }
            return Data("photo".utf8)
        }
        #expect(viewModel.canAdvance)
        viewModel.nextStep()
        release.yield()
        await viewModel.imageLoader.currentLoad?.value

        #expect(viewModel.step == .recurrence)
        #expect(viewModel.request.imageData == Data("photo".utf8))
        #expect(!viewModel.isLoadingImage)
    }

    @Test("Create waits for a photo that is still loading")
    func createWaitsForLoadingPhoto() async {
        let viewModel = NewTransactionViewModel()
        viewModel.step = .notesImage
        let (gate, release) = AsyncStream.makeStream(of: Void.self)

        viewModel.loadImage {
            for await _ in gate { break }
            return Data("photo".utf8)
        }
        #expect(viewModel.isLastStep)
        #expect(!viewModel.canAdvance)

        release.yield()
        await viewModel.imageLoader.currentLoad?.value
        #expect(viewModel.canAdvance)
    }
}
