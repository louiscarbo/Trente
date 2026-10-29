//
//  PendingTransactionReviewView+AllowanceNote.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 29/10/2026.
//

import SwiftUI

extension PendingTransactionReviewView {
    struct AllowanceNote: View {
        let loggedCount: Int
        let limit: Int

        var body: some View {
            Label(
                "\(loggedCount) of \(limit) free Apple Pay logs this month",
                systemImage: "creditcard"
            )
            .font(.footnote)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview {
    PendingTransactionReviewView.AllowanceNote(loggedCount: 7, limit: 10)
        .padding()
}
