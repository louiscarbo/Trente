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
}
