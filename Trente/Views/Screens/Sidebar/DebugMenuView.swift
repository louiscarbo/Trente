//
//  DebugMenuView.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 23/10/2026.
//

#if DEBUG
import SwiftUI
import StoreKit

struct DebugMenuView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.replayOnboarding) private var replayOnboarding
    @Environment(\.requestReview) private var requestReview

    @State private var pendingTransactionRouter = PendingTransactionRouter.shared

    var body: some View {
        NavigationStack {
            List {
                NavigationLink {
                    PendingTransactionsDebugView()
                } label: {
                    Label("Pending Transactions", systemImage: "tray")
                }
                Button {
                    dismiss()
                    replayOnboarding()
                } label: {
                    Label("Onboarding", systemImage: "sparkles")
                }
                Button {
                    requestReview()
                } label: {
                    Label("Request Review Now", systemImage: "star")
                }
                Button {
                    ReviewRequestPolicy.reset()
                } label: {
                    Label("Reset Review Prompt", systemImage: "arrow.counterclockwise")
                }
            }
            .navigationTitle("Debug")
            .onChange(of: pendingTransactionRouter.presentedPendingTransactionID) { _, id in
                if id != nil { dismiss() }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 420, minHeight: 360)
        #endif
    }
}
#endif
