//
//  RecurringTransactionRuleDetailsView+StopBox.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 27/10/2026.
//

import SwiftUI

extension RecurringTransactionRuleDetailsView {
    struct StopBox: View {
        let title: String
        var onStop: () -> Void

        @State private var showConfirmation = false

        var body: some View {
            let explanation = String(localized: "\(title) won't appear after today. Transactions already recorded stay.")
            GroupBox(label: Label("Stop Future Transactions", systemImage: "stop.circle.fill")) {
                VStack(spacing: .medium) {
                    Text(explanation)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundStyle(.secondary)
                    Button {
                        showConfirmation = true
                    } label: {
                        Label("Stop Future Transactions", systemImage: "stop.circle.fill")
                            .font(.headline)
                    }
                    .buttonStyle(TrentePrimaryButtonStyle(narrow: true))
                    .confirmationDialog(
                        String(localized: "Stop future \(title) transactions?"),
                        isPresented: $showConfirmation,
                        titleVisibility: .visible
                    ) {
                        Button(String(localized: "Stop Future Transactions"), role: .destructive, action: onStop)
                        Button(String(localized: "Cancel"), role: .cancel) {}
                    } message: {
                        Text(explanation)
                    }
                }
            }
            .groupBoxStyle(TrenteGroupBoxStyle())
        }
    }
}
