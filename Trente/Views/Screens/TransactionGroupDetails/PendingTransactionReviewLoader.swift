//
//  PendingTransactionReviewLoader.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 07/10/2026.
//

import SwiftUI
import SwiftData

struct PendingTransactionReviewLoader: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var pendingTransactions: [PendingTransaction]

    init(id: UUID) {
        _pendingTransactions = Query(filter: #Predicate<PendingTransaction> { $0.id == id })
    }

    var body: some View {
        if let pending = pendingTransactions.first {
            PendingTransactionReviewView(pending: pending)
        } else {
            Color.clear
                .onAppear { dismiss() }
        }
    }
}
