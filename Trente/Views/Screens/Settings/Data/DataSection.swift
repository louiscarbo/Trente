//
//  DataSection.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 24/10/2026.
//

import SwiftUI

struct DataSection: View {
    let syncStatus: CloudSyncStatus

    var body: some View {
        Section {
            LabeledContent("iCloud Sync") {
                syncStatusText
            }
            NavigationLink {
                TransactionExportView()
            } label: {
                Label("Export Transactions", systemImage: "tablecells")
            }
        } header: {
            Text("Your Data")
        } footer: {
            Text(footer)
        }
    }

    @ViewBuilder
    private var syncStatusText: some View {
        switch syncStatus {
        case .signedOut:
            Text("Off")
        case .waiting:
            Text("On")
        case .synced(let date):
            Text("Synced \(date, format: .relative(presentation: .named))")
        case .failed:
            Text("Not Synced")
        }
    }

    private var footer: LocalizedStringKey {
        switch syncStatus {
        case .signedOut:
            "Sign in to iCloud in the Settings app to keep your months and transactions on all your devices. You can export them as a spreadsheet anytime."
        case .failed(let description):
            "iCloud couldn't sync: \(description). You can export your data as a spreadsheet anytime."
        case .waiting, .synced:
            """
            Your months and transactions sync through your iCloud account on all your devices. \
            Trente has no account and no server. You can export them as a spreadsheet anytime.
            """
        }
    }
}

#Preview {
    NavigationStack {
        Form {
            DataSection(syncStatus: .synced(.now.addingTimeInterval(-120)))
            DataSection(syncStatus: .signedOut)
        }
        .formStyle(.grouped)
    }
}
