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

    @Test("A picked photo still lands after leaving its step")
    func photoSurvivesLeavingTheStep() async {
        let viewModel = NewTransactionViewModel()
        viewModel.request.type = .income
        viewModel.step = .notesImage
        let (gate, release) = AsyncStream.makeStream(of: Void.self)

        viewModel.loadImage {
            for await _ in gate { break }
            return Data("photo".utf8)
        }
        #expect(viewModel.canAdvance)
        viewModel.nextStep()
        release.yield()
        await viewModel.imageLoad?.value

        #expect(viewModel.step == .repartition)
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
        await viewModel.imageLoad?.value
        #expect(viewModel.canAdvance)
    }

    @Test("A newer photo wins over a slower older one")
    func newerPhotoWins() async {
        let viewModel = NewTransactionViewModel()
        let (gate, release) = AsyncStream.makeStream(of: Void.self)

        viewModel.loadImage {
            for await _ in gate { break }
            return Data("older".utf8)
        }
        let olderLoad = viewModel.imageLoad
        viewModel.loadImage { Data("newer".utf8) }
        await viewModel.imageLoad?.value
        release.yield()
        await olderLoad?.value

        #expect(viewModel.request.imageData == Data("newer".utf8))
        #expect(!viewModel.isLoadingImage)
    }

    @Test("A failed photo shows an error and keeps the current image")
    func failedPhotoKeepsCurrentImage() async {
        let viewModel = NewTransactionViewModel()
        viewModel.request.imageData = Data("current".utf8)

        viewModel.loadImage { throw CocoaError(.fileReadUnknown) }
        await viewModel.imageLoad?.value

        #expect(viewModel.request.imageData == Data("current".utf8))
        #expect(viewModel.imageLoadingError != nil)
        #expect(!viewModel.isLoadingImage)
    }
}
