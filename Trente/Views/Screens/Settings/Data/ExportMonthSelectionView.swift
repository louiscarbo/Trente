//
//  ExportMonthSelectionView.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 24/10/2026.
//

import SwiftUI

struct ExportMonthSelectionView: View {
    let options: [ExportMonthOption]
    @Binding var excludedMonthIDs: Set<UUID>

    var body: some View {
        Form {
            ForEach(ExportMonthOption.groupedByYear(options)) { group in
                Section {
                    ForEach(group.options) { option in
                        Row(
                            option: option,
                            isSelected: !excludedMonthIDs.contains(option.id),
                            onToggle: { toggle(option.id) }
                        )
                    }
                } header: {
                    Text(group.year, format: .number.grouping(.never))
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Months")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(selectAllTitle, action: toggleAll)
            }
        }
    }

    private var selectAllTitle: LocalizedStringKey {
        excludedMonthIDs.isEmpty ? "Deselect All" : "Select All"
    }

    private func toggle(_ monthID: UUID) {
        if excludedMonthIDs.contains(monthID) {
            excludedMonthIDs.remove(monthID)
        } else {
            excludedMonthIDs.insert(monthID)
        }
    }

    private func toggleAll() {
        excludedMonthIDs = excludedMonthIDs.isEmpty ? Set(options.map(\.id)) : []
    }
}

#Preview {
    NavigationStack {
        ExportMonthSelectionView(
            options: [
                ExportMonthOption(id: UUID(), name: "October 2026", startDate: .now, transactionCount: 24),
                ExportMonthOption(id: UUID(), name: "September 2026", startDate: .now.addingTimeInterval(-2_600_000), transactionCount: 31)
            ],
            excludedMonthIDs: .constant([])
        )
    }
}
