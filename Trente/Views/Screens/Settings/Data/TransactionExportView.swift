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
    @Query(TransactionExportRow.groupsWithImagesDescriptor) private var groupsWithImages: [TransactionGroup]

    @AppStorage(TransactionCSVFormat.styleKey) private var style = TransactionCSVFormat.Style.standard
    @AppStorage(TransactionCSVFormat.includesNotesKey) private var includesNotes = true
    @AppStorage(TransactionCSVFormat.includesImagesKey) private var includesImages = true
    @State private var excludedMonthIDs: Set<UUID> = []

    var body: some View {
        let options = months.map(ExportMonthOption.init(month:))
        let selectedOptions = options.filter { option in !excludedMonthIDs.contains(option.id) }
        let transactionCount = selectedOptions.reduce(0) { total, option in total + option.transactionCount }
        let monthIDsWithImages = Set(groupsWithImages.map(\.month.id))
        let file = TransactionsCSVFile(
            monthIDs: selectedOptions.map(\.id),
            fileName: TransactionsCSVFile.fileName(
                forMonthsStartingOn: selectedOptions.map(\.startDate),
                includesEveryMonth: excludedMonthIDs.isEmpty
            ),
            format: TransactionCSVFormat(style: style, includesNotes: includesNotes, includesImages: includesImages),
            hasImages: selectedOptions.contains { option in monthIDsWithImages.contains(option.id) }
        )

        Form {
            Section {
                NavigationLink {
                    ExportMonthSelectionView(
                        options: options,
                        excludedMonthIDs: $excludedMonthIDs
                    )
                } label: {
                    LabeledContent("Months") {
                        Text(monthsSummary(selectedCount: selectedOptions.count))
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
                if file.hasImages {
                    Toggle("Include Images", isOn: $includesImages)
                }
            } header: {
                Text("File")
            } footer: {
                VStack(alignment: .leading, spacing: .small) {
                    Text(formatFooter)
                    if file.includesImages {
                        Text("Images are saved next to the spreadsheet in a .zip file.")
                    }
                }
            }
        }
        .formStyle(.grouped)
        .safeAreaInset(edge: .bottom) {
            ExportButton(
                title: "Export ^[\(transactionCount) Transaction](inflect: true)",
                file: file
            )
            .disabled(transactionCount == 0)
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
