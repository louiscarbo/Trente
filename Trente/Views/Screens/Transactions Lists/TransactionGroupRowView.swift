//
//  TransactionRowView.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 17/04/2025.
//

import SwiftUI

struct TransactionGroupRowView: View {
    @Environment(\.modelContext) private var modelContext
    @State var transactionGroup: TransactionGroup
    @State var isInList = false

    @State private var showDeleteConfirmation = false
    @State private var showDetailsInEdit = false

    var body: some View {
        Group {
            if transactionGroup.entries.count > 1 {
                groupDisclosure
            } else if transactionGroup.entries.count == 1 {
                TransactionEntryRowView(
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
        .deleteConfirmation(isPresented: $showDeleteConfirmation) {
            TransactionService.shared.delete(group: transactionGroup, in: modelContext)
            try? modelContext.save()
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
                    TransactionEntryRowView(
                        transactionGroup: transactionGroup,
                        transactionEntry: entry
                    )
                }
            }
            .padding(.leading)
        } label: {
            TransactionGroupSummaryRow(transactionGroup: transactionGroup)
        }
    }
}

private struct TransactionEntryRowView: View {
    @State var transactionGroup: TransactionGroup
    @State var transactionEntry: TransactionEntry
    @State var title: String?
    
    @State private var showTransactionGroupDetails: Bool = false
    
    var body: some View {
        Button {
            showTransactionGroupDetails = true
        } label: {
            TransactionEntryRowContent(transactionEntry: transactionEntry, title: title)
        }
        .contentShape(.rect)
        .buttonStyle(.plain)
        .sheet(isPresented: $showTransactionGroupDetails) {
            TransactionGroupDetailsView(transactionGroup: transactionGroup)
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
