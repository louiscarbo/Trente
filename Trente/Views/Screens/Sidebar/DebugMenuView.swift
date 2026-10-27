//
//  DebugMenuView.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 23/10/2026.
//

#if DEBUG
import SwiftUI

struct DebugMenuView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.replayOnboarding) private var replayOnboarding

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
            }
            .navigationTitle("Debug")
            .onChange(of: pendingTransactionRouter.presentedPendingTransactionID) { _, id in
                if id != nil { dismiss() }
            }
            .toolbar {
                CloseToolbarItem { dismiss() }
            }
        }
        #if os(macOS)
        .frame(minWidth: 420, minHeight: 360)
        #endif
    }
}
#endif
