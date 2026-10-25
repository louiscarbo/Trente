//
//  TransactionExportView.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 24/10/2026.
//

import SwiftUI
import SwiftData

struct TransactionExportView: View {
    @Query(sort: \Month.startDate, order: .reverse) private var months: [Month]

    @AppStorage(TransactionCSVFormat.styleKey) private var style = TransactionCSVFormat.Style.standard
    @AppStorage(TransactionCSVFormat.includesNotesKey) private var includesNotes = true
    @State private var excludedMonthIDs: Set<UUID> = []

    var body: some View {
        let selectedMonths = months.filter { month in !excludedMonthIDs.contains(month.id) }
        let rows = TransactionExportRow.rows(from: selectedMonths)
        let transactionCount = Set(rows.map(\.transactionID)).count

        Form {
            Section {
                NavigationLink {
                    ExportMonthSelectionView(
                        options: months.map(ExportMonthOption.init(month:)),
                        excludedMonthIDs: $excludedMonthIDs
                    )
                } label: {
                    LabeledContent("Months") {
                        Text(monthsSummary(selectedCount: selectedMonths.count))
                    }
                }
            } header: {
                Text("What to Export")
            }

            Section {
                Picker("Format", selection: $style) {
                    ForEach(TransactionCSVFormat.Style.allCases) { style in
                        Text(style.title)
                            .tag(style)
                    }
                }
                Toggle("Include Notes", isOn: $includesNotes)
            } header: {
                Text("File")
            } footer: {
                Text(formatFooter)
            }
        }
        .formStyle(.grouped)
        .safeAreaInset(edge: .bottom) {
            ExportButton(
                title: "Export ^[\(transactionCount) Transaction](inflect: true)",
                file: TransactionsCSVFile(
                    rows: rows,
                    fileName: TransactionsCSVFile.fileName(
                        forMonthsStartingOn: selectedMonths.map(\.startDate),
                        includesEveryMonth: excludedMonthIDs.isEmpty
                    ),
                    format: TransactionCSVFormat(style: style, includesNotes: includesNotes)
                )
            )
            .padding()
            .background(.bar)
        }
        .navigationTitle("Export Transactions")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    private var formatFooter: LocalizedStringKey {
        switch style {
        case .standard:
            "Opens in Numbers, Google Sheets and Excel in English."
        case .european:
            "Uses semicolons and decimal commas, as Excel expects in French, German, Spanish or Italian."
        }
    }

    private func monthsSummary(selectedCount: Int) -> LocalizedStringKey {
        if excludedMonthIDs.isEmpty {
            return "All Months"
        }
        return "^[\(selectedCount) Month](inflect: true)"
    }
}

#Preview {
    NavigationStack {
        TransactionExportView()
    }
    .modelContainer(DataProvider.shared.modelContainer)
}
