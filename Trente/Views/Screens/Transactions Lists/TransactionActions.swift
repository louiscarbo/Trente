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

    func delete(_ month: Month, in context: ModelContext) {
        perform {
            MonthService.shared.delete(month: month, in: context)
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

    func discard(_ pending: PendingTransaction, in context: ModelContext) {
        perform {
            try PendingTransactionService.shared.discard(pending, in: context)
        }
    }

    func delete(_ groups: [TransactionGroup], in context: ModelContext) {
        performBatchDeletion {
            try BatchDeleteService.shared.delete(groups: groups, in: context)
        }
    }

    func delete(_ rules: [RecurringTransactionRule], in context: ModelContext) {
        performBatchDeletion {
            try BatchDeleteService.shared.delete(rules: rules, in: context)
        }
    }

    func delete(_ months: [Month], in context: ModelContext) {
        performBatchDeletion {
            try BatchDeleteService.shared.delete(months: months, in: context)
        }
    }

    private func perform(_ action: () throws -> Void) {
        do {
            try action()
        } catch {
            reportError(error.localizedDescription)
        }
    }

    private func performBatchDeletion(_ action: () throws -> Void) {
        do {
            try action()
        } catch {
            reportError(String(localized: "Nothing was deleted. \(error.localizedDescription)"))
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
