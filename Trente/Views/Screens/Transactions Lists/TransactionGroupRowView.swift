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

    @State private var showDeleteConfirmation = false
    @State private var showDetailsInEdit = false

    var body: some View {
        Group {
            if transactionGroup.entries.count > 1 {
                groupDisclosure
            } else if transactionGroup.entries.count == 1 {
                EntryRow(
                    transactionGroup: transactionGroup,
                    transactionEntry: transactionGroup.entries[0],
                    title: transactionGroup.title
                )
            } else {
                EmptyView()
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                showDeleteConfirmation = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
            Button {
                showDetailsInEdit = true
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            .tint(.orange)
        }
        .contextMenu {
            Button("Edit", systemImage: "pencil") {
                showDetailsInEdit = true
            }
            Button("Delete", systemImage: "trash", role: .destructive) {
                showDeleteConfirmation = true
            }
        }
        .deleteConfirmation(isPresented: $showDeleteConfirmation) {
            transactionActions.delete(transactionGroup, in: modelContext)
        }
        .sheet(isPresented: $showDetailsInEdit) {
            TransactionGroupDetailsView(
                transactionGroup: transactionGroup,
                startInEditMode: true
            )
        }
        .clipShape(Rectangle().inset(by: -3))
    }
    
    private var groupDisclosure: some View {
        DisclosureGroup {
            VStack {
                if !isInList {
                    Divider()
                }
                ForEach(transactionGroup.entries) { entry in
                    EntryRow(
                        transactionGroup: transactionGroup,
                        transactionEntry: entry
                    )
                }
            }
            .padding(.leading)
        } label: {
            TransactionGroupSummaryRow(
                title: transactionGroup.title,
                amount: transactionGroup.totalAmount,
                currencyCode: transactionGroup.currency.isoCode
            )
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
