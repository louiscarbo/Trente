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

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PendingTransaction.date, order: .reverse) private var pendingTransactions: [PendingTransaction]
    @Query(sort: \Month.startDate, order: .reverse) private var months: [Month]

    @State private var pendingTransactionRouter = PendingTransactionRouter.shared
    @State private var reviewedID: UUID?
    @State private var errorMessage: String?

    private var currencyCode: String { months.first?.currency.isoCode ?? "EUR" }

    var body: some View {
        NavigationStack {
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
            .navigationTitle("Pending (debug)")
            .onChange(of: pendingTransactionRouter.presentedPendingTransactionID) { _, id in
                if id != nil { dismiss() }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Add sample", systemImage: "plus", action: addSample)
                }
            }
            .sheet(isPresented: isShowingReview) {
                if let reviewedID {
                    PendingTransactionReviewLoader(id: reviewedID)
                }
            }
            .alert("Wallet intake failed", isPresented: isShowingError) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private var isShowingReview: Binding<Bool> {
        Binding(
            get: { reviewedID != nil },
            set: { if !$0 { reviewedID = nil } }
        )
    }

    private var isShowingError: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )
    }

    private func row(for pending: PendingTransaction) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(pending.title)
                Text(pending.category?.name ?? "No category")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
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
