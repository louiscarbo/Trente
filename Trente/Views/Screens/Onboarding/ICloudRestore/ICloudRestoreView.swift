//
//  ICloudRestoreView.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 26/10/2026.
//

import SwiftData
import SwiftUI

struct ICloudRestoreView: View {
    let onContinue: () -> Void
    let onNothingFound: () -> Void

    @Query private var months: [Month]
    @Query private var transactions: [TransactionGroup]
    @State private var syncMonitor = CloudSyncMonitor.shared

    private var decision: ICloudRestoreGate.Decision {
        ICloudRestoreGate.decision(
            accountStatus: syncMonitor.accountStatus,
            didFinishImport: syncMonitor.didFinishImport,
            monthCount: months.count
        )
    }

    var body: some View {
        Group {
            if decision == .welcomeBack {
                WelcomeBackStepView(
                    monthCount: months.count,
                    transactionCount: transactions.count,
                    onContinue: onContinue
                )
            } else {
                ICloudSearchStepView(onSetUpAsNew: onNothingFound)
            }
        }
        .animation(.default, value: decision)
        .onChange(of: decision, initial: true) { _, newDecision in
            if newDecision == .onboarding {
                onNothingFound()
            }
        }
        .task {
            do {
                try await Task.sleep(for: ICloudRestoreGate.timeout)
            } catch {
                return
            }
            if decision == .searching {
                onNothingFound()
            }
        }
    }
}
