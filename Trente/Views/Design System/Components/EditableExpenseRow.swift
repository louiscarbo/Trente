//
//  EditableExpenseRow.swift
//  Trente
//

import SwiftUI

struct EditableExpenseRow: View {
    var isEditing: Bool
    @Binding var category: BudgetCategory?
    @Binding var amountCents: Int
    var currency: Currency
    var focus: FocusState<Bool>.Binding

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack {
                EditableCategoryRow(isEditing: isEditing, category: $category)
                    .layoutPriority(1)
                EditableAmountRow(
                    isEditing: isEditing,
                    amountCents: $amountCents,
                    currency: currency,
                    focus: focus
                )
                .layoutPriority(0)
            }
            VStack(alignment: .leading, spacing: .small) {
                EditableCategoryRow(isEditing: isEditing, category: $category)
                EditableAmountRow(
                    isEditing: isEditing,
                    amountCents: $amountCents,
                    currency: currency,
                    focus: focus
                )
            }
        }
    }
}
