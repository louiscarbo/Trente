import FoundationModels

protocol TransactionSuggesting: Sendable {
    func suggestCategory(for transaction: WalletTransaction) async throws -> BudgetCategory?
}

struct TransactionSuggester: TransactionSuggesting {
    func suggestCategory(for transaction: WalletTransaction) async throws -> BudgetCategory? {
        guard case .available = SystemLanguageModel.default.availability else { return nil }

        let session = LanguageModelSession(instructions: WalletSuggestionPrompt.instructions)
        let response = try await session.respond(
            to: WalletSuggestionPrompt.prompt(for: transaction),
            generating: TransactionSuggestion.self,
            options: GenerationOptions(samplingMode: .greedy)
        )
        return response.content.category?.budgetCategory
    }
}
