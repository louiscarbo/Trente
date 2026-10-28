//
//  PendingTransactionsDebugView.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 07/10/2026.
//

#if DEBUG
import SwiftUI
import SwiftData

struct PendingTransactionsDebugView: View {
    private static let samples: [(transaction: String, amount: String)] = [
        ("Dia", "53,74 €"),
        ("Teika M Vending", "0,50 €"),
        ("Carrefour Express", "12,30 €"),
        ("Cabify", "8,90 €"),
        ("Renfe", "34,10 €")
    ]

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PendingTransaction.date, order: .reverse) private var pendingTransactions: [PendingTransaction]
    @Query(sort: \Month.startDate, order: .reverse) private var months: [Month]

    @State private var reviewedID: UUID?
    @State private var errorMessage: String?

    private var currencyCode: String { months.first?.currency.isoCode ?? "EUR" }

    var body: some View {
        List {
            ForEach(pendingTransactions) { pending in
                Button {
                    reviewedID = pending.id
                } label: {
                    row(for: pending)
                }
                .buttonStyle(.plain)
            }
            .onDelete(perform: delete)
        }
        .overlay {
            if pendingTransactions.isEmpty {
                ContentUnavailableView("No pending transactions", systemImage: "tray")
            }
        }
        .navigationTitle("Pending Transactions")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Add sample", systemImage: "plus", action: addSample)
            }
        }
        .sheet(isPresented: $reviewedID.isPresent()) {
            if let reviewedID {
                PendingTransactionReviewLoader(id: reviewedID)
            }
        }
        .errorAlert("Wallet intake failed", message: $errorMessage)
    }

    private func row(for pending: PendingTransaction) -> some View {
        HStack {
            Text(pending.title)
            Spacer()
            Text(Double(pending.amountCents) / 100.0, format: .currency(code: currencyCode))
        }
    }

    private func addSample() {
        guard let sample = Self.samples.randomElement() else { return }
        Task {
            do {
                try await WalletIntakeService().handle(
                    transaction: sample.transaction,
                    amount: sample.amount,
                    in: modelContext
                )
            } catch {
                errorMessage = "\(error)"
            }
        }
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(pendingTransactions[index])
        }
        try? modelContext.save()
    }
}
#endif
