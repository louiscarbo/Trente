//
//  MonthDetailsView+ExportSection.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 12/08/2025.
//

import SwiftUI
import SwiftData

extension MonthDetailsView {
    struct ExportSection: View {
        let file: TransactionsCSVFile
        let isEmpty: Bool

        var body: some View {
            GroupBox(label: Label("Export Month", systemImage: "square.and.arrow.up")) {
                VStack(spacing: .medium) {
                    Text(description)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    ExportButton(title: "Export…", file: file)
                        .disabled(isEmpty)

                    Text("To export several months or choose what to include, go to Settings › Export Transactions.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .groupBoxStyle(TrenteGroupBoxStyle())
        }

        private var description: LocalizedStringKey {
            if isEmpty {
                "This month has no transactions to export yet."
            } else if file.includesImages {
                "Save this month's transactions and their images in a .zip file, with a spreadsheet (.csv) that opens in Numbers, Excel or Google Sheets."
            } else {
                "Save this month's transactions as a spreadsheet file (.csv) that opens in Numbers, Excel or Google Sheets."
            }
        }
    }
}
