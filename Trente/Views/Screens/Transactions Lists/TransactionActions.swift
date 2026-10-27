//
//  TransactionActions.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 27/10/2026.
//

import SwiftData
import SwiftUI

struct TransactionActions {
    let reportError: (String) -> Void

    func delete(_ group: TransactionGroup, in context: ModelContext) {
        perform {
            TransactionService.shared.delete(group: group, in: context)
            try context.save()
        }
    }

    func delete(_ rule: RecurringTransactionRule, in context: ModelContext) {
        perform {
            RecurringTransactionService.shared.delete(rule: rule, in: context)
            try context.save()
        }
    }

    func confirm(_ occurrence: RecurringTransactionOccurrence, in context: ModelContext) {
        perform {
            try RecurringTransactionService.shared.confirm(occurrence, in: context)
        }
    }

    func skip(_ occurrence: RecurringTransactionOccurrence, in context: ModelContext) {
        perform {
            try RecurringTransactionService.shared.skip(occurrence, in: context)
        }
    }

    private func perform(_ action: () throws -> Void) {
        do {
            try action()
        } catch {
            reportError(error.localizedDescription)
        }
    }
}

extension EnvironmentValues {
    @Entry var transactionActions = TransactionActions { _ in }
}

private struct TransactionActionsErrorAlert: ViewModifier {
    @State private var errorMessage: String?

    func body(content: Content) -> some View {
        content
            .environment(\.transactionActions, TransactionActions { errorMessage = $0 })
            .errorAlert(message: $errorMessage)
    }
}

extension View {
    func transactionActionsErrorAlert() -> some View {
        modifier(TransactionActionsErrorAlert())
    }
}
