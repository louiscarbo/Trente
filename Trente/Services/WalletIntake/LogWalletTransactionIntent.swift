//
//  LogWalletTransactionIntent.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 07/10/2026.
//

import AppIntents

struct LogWalletTransactionIntent: AppIntent {
    static let title: LocalizedStringResource = "Log Wallet Transaction"
    static let description = IntentDescription(
        "Prepares an expense from an Apple Pay payment so you can review it in Trente."
    )
    static let openAppWhenRun = false

    @Parameter(title: "Merchant")
    var merchant: String

    @Parameter(title: "Amount")
    var amount: String

    @Parameter(title: "Name")
    var name: String?

    @Parameter(title: "Card")
    var card: String?

    @MainActor
    func perform() async throws -> some IntentResult {
        do {
            try await WalletIntakeService().handle(
                merchant: merchant,
                name: name ?? "",
                amount: amount,
                card: card ?? "",
                in: TrenteContainer.shared.mainContext
            )
        } catch {
            #if DEBUG
            await WalletNotificationService.shared.postDebugFailure("\(error)")
            #endif
        }
        return .result()
    }
}
