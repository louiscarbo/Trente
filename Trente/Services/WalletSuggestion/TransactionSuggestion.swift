import FoundationModels

@Generable
enum SuggestedCategory: CaseIterable {
    case needs
    case wants
    case savingsAndDebts

    var budgetCategory: BudgetCategory {
        switch self {
        case .needs: .needs
        case .wants: .wants
        case .savingsAndDebts: .savingsAndDebts
        }
    }
}

@Generable
struct TransactionSuggestion {
    @Guide(description: "Budget category, or nil when the transaction is unclear or could fit several")
    var category: SuggestedCategory?
}
