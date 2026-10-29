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

    @AppStorage(TransactionCSVFormat.includesNotesKey) private var includesNotes = true
    @AppStorage(TransactionCSVFormat.includesImagesKey) private var includesImages = true
    @State private var excludedMonthIDs: Set<UUID> = []

    private var selection: ExportSelection {
        ExportSelection(
            options: months.map(ExportMonthOption.init(month:)),
            excludedMonthIDs: excludedMonthIDs,
            monthIDsWithImages: Set(groupsWithImages.compactMap(\.month?.id)),
            format: TransactionCSVFormat(style: .current, includesNotes: includesNotes, includesImages: includesImages)
        )
    }

    var body: some View {
        let selection = selection
        let file = selection.file

        Form {
            Section {
                NavigationLink {
                    ExportMonthSelectionView(
                        options: selection.options,
                        excludedMonthIDs: $excludedMonthIDs
                    )
                } label: {
                    LabeledContent("Months") {
                        Text(monthsSummary(of: selection))
                    }
                }
            } header: {
                Text("What to Export")
            }

            Section {
                Toggle("Include Notes", isOn: $includesNotes)
                if file.hasImages {
                    Toggle("Include Images", isOn: $includesImages)
                }
            } header: {
                Text("File")
            } footer: {
                if file.includesImages {
                    Text("Images are saved next to the spreadsheet in a .zip file.")
                }
            }
        }
        .formStyle(.grouped)
        .safeAreaInset(edge: .bottom) {
            ExportButton(
                title: "Export ^[\(selection.transactionCount) Transaction](inflect: true)",
                file: file
            )
            .disabled(selection.transactionCount == 0)
            .padding()
            .background(.bar)
        }
        .navigationTitle("Export Transactions")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    private func monthsSummary(of selection: ExportSelection) -> LocalizedStringKey {
        if selection.includesEveryMonth {
            return "All Months"
        }
        return "^[\(selection.selectedOptions.count) Month](inflect: true)"
    }
}

#Preview {
    NavigationStack {
        TransactionExportView()
    }
    .modelContainer(DataProvider.shared.modelContainer)
}
