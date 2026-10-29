//
//  TransactionRowView.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 17/04/2025.
//

import SwiftData
import SwiftUI

struct TransactionGroupRowView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.transactionActions) private var transactionActions
    let transactionGroup: TransactionGroup
    var isInList = false

    private enum DetailsMode: Identifiable {
        case reading, editing

        var id: Self { self }
    }

    @State private var groupToDelete: TransactionGroup?
    @State private var presentedDetails: DetailsMode?

    var body: some View {
        Content(
            title: transactionGroup.title,
            entries: entries,
            totalAmount: transactionGroup.totalAmount,
            currencyCode: transactionGroup.currency.isoCode,
            isInList: isInList
        ) {
            presentedDetails = .reading
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                groupToDelete = transactionGroup
            } label: {
                Label("Delete", systemImage: "trash")
            }
            Button {
                presentedDetails = .editing
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            .tint(.orange)
        }
        .contextMenu {
            Button("Edit", systemImage: "pencil") {
                presentedDetails = .editing
            }
            Button("Delete", systemImage: "trash", role: .destructive) {
                groupToDelete = transactionGroup
            }
        }
        .deleteConfirmation(item: $groupToDelete) { group in
            transactionActions.delete(group, in: modelContext)
        }
        .sheet(item: $presentedDetails) { mode in
            TransactionGroupDetailsView(
                transactionGroup: transactionGroup,
                startInEditMode: mode == .editing
            )
        }
        .clipShape(Rectangle().inset(by: -3))
    }

    private var entries: [(category: BudgetCategory, amount: Double)] {
        transactionGroup.entries.map { entry in
            (entry.category, entry.amount)
        }
    }
}

#Preview {
    let month = Month.month1
    
    VStack {
        Text("Transactions")
        ForEach(month.transactionGroups.sorted {
            $0.addedDate > $1.addedDate
        }) { transaction in
            TransactionGroupRowView(transactionGroup: transaction)
        }
    }
}
