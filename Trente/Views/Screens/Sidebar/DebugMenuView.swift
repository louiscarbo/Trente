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
    @State private var paywallRouter = PaywallRouter.shared
    @State private var trentePlus = TrentePlusStatus.shared

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
                Picker(selection: $trentePlus.debugOverride) {
                    Text("App Store").tag(TrentePlusDebugOverride.appStore)
                    Text("Subscribed").tag(TrentePlusDebugOverride.subscribed)
                    Text("Not Subscribed").tag(TrentePlusDebugOverride.notSubscribed)
                } label: {
                    Label("Trente+", systemImage: "plus.circle")
                }
            }
            .navigationTitle("Debug")
            .onChange(of: pendingTransactionRouter.presentedPendingTransactionID) { _, id in
                if id != nil { dismiss() }
            }
            .onChange(of: paywallRouter.isPresentingPaywall) { _, isPresenting in
                if isPresenting { dismiss() }
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
