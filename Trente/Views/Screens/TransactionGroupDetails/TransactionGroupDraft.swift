//
//  TransactionGroupDraft.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 27/09/2025.
//

import Foundation
import SwiftData

// Draft mirrors what the screen edits, not necessarily the entire model.
// Keep it value-typed for easy discard.
struct TransactionGroupDraft: Equatable {
    // Always editable
    var title: String
    var note: String
    
    var imageAttachmentData: Data?

    // Expense-only fields
    var expenseCategory: BudgetCategory?
    var expenseAmountCents: Int = 0 {
        didSet {
            if expenseAmountCents > 0 {
                expenseAmountCents = -expenseAmountCents
            }
        }
    }

    // Income-only fields: repartition per category in cents
    // Must sum to total amount you want to split
    var incomeRepartition: [BudgetCategory: Int] = [:]
    var incomeAmountToSplitCents: Int = 0

    var type: TransactionType

    // MARK: Init from model
    init(from group: TransactionGroup) {
        self.title = group.title
        self.note = group.note ?? ""
        self.imageAttachmentData = group.imageAttachmentData
        self.type = group.type

        switch group.type {
        case .expense:
            // For expense we expect exactly one entry carrying category+amount
            let e = group.entries.first
            self.expenseCategory = e?.category
            self.expenseAmountCents = e?.amountCents ?? 0
        case .income:
            // For income, derive repartition from entries.
            // If entries are empty, leave blank; the UI can fill it.
            var dict: [BudgetCategory: Int] = [:]
            var total = 0
            for e in group.entries {
                dict[e.category, default: 0] += e.amountCents
                total += e.amountCents
            }
            self.incomeRepartition = dict
            self.incomeAmountToSplitCents = max(total, 0)
        }
    }

    init(from pending: PendingTransaction) {
        self.title = pending.title
        self.note = ""
        self.type = .expense
        self.expenseAmountCents = pending.amountCents
    }

    // MARK: Apply back into model (mutates group and entries)
    func apply(to group: TransactionGroup, context: ModelContext) {
        group.title = title
        group.note = note.isEmpty ? nil : note
        // imageAttachmentData stays read-only for now in UI, but carry over any pre-existing value.
        group.imageAttachmentData = imageAttachmentData

        switch type {
        case .expense:
            let cat = expenseCategory
            let amt = expenseAmountCents
            if group.entries.isEmpty {
                let entry = TransactionEntry(
                    amountCents: amt,
                    category: cat ?? .needs,
                    group: group
                )
                context.insert(entry)
                group.entries = [entry]
            } else {
                group.entries[0].category = cat ?? group.entries[0].category
                group.entries[0].amountCents = amt
                // Delete extra entries before removing from the array
                if group.entries.count > 1 {
                    for entry in group.entries[1...] { context.delete(entry) }
                    group.entries.removeSubrange(1...)
                }
            }

        case .income:
            let filtered = incomeRepartition.filter { $0.value != 0 }
            for entry in group.entries { context.delete(entry) }
            group.entries = filtered.map { (cat, cents) in
                let entry = TransactionEntry(amountCents: cents, category: cat, group: group)
                context.insert(entry)
                return entry
            }
        }

        group.modifiedDate = .now
    }

    mutating func fillMissingAmountToSplit() {
        guard type == .income, incomeAmountToSplitCents == 0 else { return }
        incomeAmountToSplitCents = incomeRepartition.values.reduce(0, +)
    }

    // MARK: Validation
    func validate() -> [String] {
        var issues: [String] = []
        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            issues.append(String(localized: "Title cannot be empty."))
        }
        switch type {
        case .expense:
            if expenseCategory == nil { issues.append(String(localized: "Select a category for the expense.")) }
            if expenseAmountCents >= 0 { issues.append(String(localized: "Amount must be less than 0.")) }
        case .income:
            let total = incomeRepartition.values.reduce(0, +)
            if total <= 0 {
                issues.append(String(localized: "Income repartition total must be greater than 0."))
            }
            if total != incomeAmountToSplitCents && incomeAmountToSplitCents > 0 {
                issues.append(String(localized: "Repartition total does not match the amount to split."))
            }
        }
        return issues
    }
}
