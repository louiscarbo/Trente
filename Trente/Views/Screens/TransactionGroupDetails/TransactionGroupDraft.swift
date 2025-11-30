//
//  TransactionGroupDraft.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 27/09/2025.
//

import Foundation

// Draft mirrors what the screen edits, not necessarily the entire model.
// Keep it value-typed for easy discard.
struct TransactionGroupDraft: Equatable {
    // Always editable
    var title: String
    var note: String?
    var imageAttachmentData: Data?

    // Expense-only fields
    var expenseCategory: BudgetCategory?
    var expenseAmountCents: Int?

    // Income-only fields: repartition per category in cents
    // Must sum to total amount you want to split
    var incomeRepartition: [BudgetCategory: Int] = [:]
    var incomeAmountToSplitCents: Int = 0

    var type: TransactionType

    // MARK: Init from model
    init(from group: TransactionGroup) {
        self.title = group.title
        self.note = group.note
        self.imageAttachmentData = group.imageAttachmentData
        self.type = group.type

        switch group.type {
        case .expense:
            // For expense we expect exactly one entry carrying category+amount
            let e = group.entries.first
            self.expenseCategory = e?.category
            self.expenseAmountCents = e?.amountCents
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

    // MARK: Apply back into model (mutates group and entries)
    func apply(to group: TransactionGroup) {
        group.title = title
        group.note = note
        // imageAttachmentData stays read-only for now in UI, but carry over any pre-existing value.
        group.imageAttachmentData = imageAttachmentData

        switch type {
        case .expense:
            // Ensure exactly one entry with the chosen category + amount
            let cat = expenseCategory
            let amt = expenseAmountCents
            // Create or update first entry; drop extras to keep invariant
            if group.entries.isEmpty {
                let entry = TransactionEntry(
                    amountCents: amt ?? 0,
                    category: cat ?? .needs, // sensible fallback
                    group: group
                )
                group.entries = [entry]
            } else {
                // Update first
                group.entries[0].category = cat ?? group.entries[0].category
                group.entries[0].amountCents = amt ?? group.entries[0].amountCents
                // Remove extra entries if any
                if group.entries.count > 1 {
                    group.entries.removeSubrange(1..<group.entries.count)
                }
            }

        case .income:
            // Translate repartition to entries (overwrite entries)
            // Keep only non-zero buckets
            let filtered = incomeRepartition.filter { $0.value != 0 }
            group.entries = filtered.map { (cat, cents) in
                TransactionEntry(
                    amountCents: cents,
                    category: cat,
                    group: group
                )
            }
        }

        group.modifiedDate = .now
    }

    // MARK: Validation
    func validate() -> [String] {
        var issues: [String] = []
        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            issues.append("Title cannot be empty.")
        }
        switch type {
        case .expense:
            if expenseCategory == nil { issues.append("Select a category for the expense.") }
            if (expenseAmountCents ?? 0) >= 0 { issues.append("Amount must be less than 0.") }
        case .income:
            let total = incomeRepartition.values.reduce(0, +)
            if total <= 0 {
                issues.append("Income repartition total must be greater than 0.")
            }
            if total != incomeAmountToSplitCents && incomeAmountToSplitCents > 0 {
                issues.append("Repartition total does not match the amount to split.")
            }
        }
        return issues
    }
}
