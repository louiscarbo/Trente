//
//  DataSection.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 24/10/2026.
//

import SwiftUI

struct DataSection: View {
    var body: some View {
        Section {
            NavigationLink {
                TransactionExportView()
            } label: {
                Label("Export Transactions", systemImage: "tablecells")
            }
        } header: {
            Text("Your Data")
        } footer: {
            Text("Trente has no account and no server: your data is yours. You can export it as a spreadsheet anytime.")
        }
    }
}

#Preview {
    NavigationStack {
        Form {
            DataSection()
        }
        .formStyle(.grouped)
    }
}
