//
//  SidebarView.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 22/04/2025.
//

import SwiftUI
import SwiftData

enum SidebarSelection: Hashable {
    case month(Month)
    case recurring

    func leaving(_ deletedMonths: [Month], for latestMonth: Month?) -> SidebarSelection? {
        guard case .month(let month) = self, deletedMonths.contains(month) else { return self }
        return latestMonth.map(SidebarSelection.month)
    }
}

struct SidebarView: View {
    let months: [Month]
    @Binding var selection: SidebarSelection?
    let showsSelection: Bool
    let onDeleteMonths: ([Month]) -> Void

    @Query private var recurringRules: [RecurringTransactionRule]

    @State private var monthSelection = RowSelection<Month.ID>()

    #if os(iOS)
    @State private var isShowingSettings = false
    #endif
    #if DEBUG
    @State private var isShowingDebugMenu = false
    #endif

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading) {
                if let currentMonth = months.first {
                    Text("CURRENT MONTH")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                        .accessibilityAddTraits(.isHeader)

                    MonthSummaryCard(
                        name: currentMonth.name,
                        remaining: currentMonth.remainingAmount,
                        spent: currentMonth.spentAmount(in: .all),
                        currencyCode: currentMonth.currency.isoCode,
                        isOverspent: currentMonth.overSpent,
                        isSelected: showsSelection && selectedMonth.wrappedValue == currentMonth
                    ) {
                        withAnimation(.easeOut) {
                            selectedMonth.wrappedValue = currentMonth
                        }
                    }
                    .inactive(isSelectingMonths)
                }

                NewMonthButton()
                    .padding(.vertical)
                    .inactive(isSelectingMonths)

                if !months.isEmpty {
                    Text("RECURRING")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                        .accessibilityAddTraits(.isHeader)
                    RecurringTransactionsRowView(
                        activeCount: recurringRules.count { !$0.hasEnded },
                        isSelected: showsSelection && selection == .recurring
                    ) {
                        selection = .recurring
                    }
                    .inactive(isSelectingMonths)
                    .padding(.bottom)
                }

                if months.count > 1 {
                    HStack {
                        Text("ARCHIVED MONTHS")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .accessibilityAddTraits(.isHeader)
                        Spacer()
                        Button(isSelectingMonths ? "Done" : "Select") {
                            withAnimation {
                                if isSelectingMonths {
                                    monthSelection.end()
                                } else {
                                    monthSelection.begin()
                                }
                            }
                        }
                        .font(.subheadline)
                        .buttonStyle(.borderless)
                    }
                    .padding(.horizontal)
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(archivedMonths) { month in
                            ArchivedMonthRow(
                                name: month.name,
                                isOverspent: month.overSpent,
                                isSelected: showsSelection && !isSelectingMonths && selectedMonth.wrappedValue == month,
                                isFirst: month == archivedMonths.first,
                                isLast: month == archivedMonths.last,
                                isChecked: isSelectingMonths ? monthSelection.selectedIDs.contains(month.id) : nil
                            ) {
                                if isSelectingMonths {
                                    monthSelection.toggle(month.id)
                                } else {
                                    withAnimation {
                                        selectedMonth.wrappedValue = month
                                    }
                                }
                            }
                        }
                    }
                    .background(
                        TrenteListBackgroundView()
                    )
                }

                Spacer()
            }
            .navigationTitle("All Months")
            #if os(iOS)
            .toolbarTitleDisplayMode(.large)
            #elseif os(macOS)
            .frame(minWidth: 200, idealWidth: 300, maxWidth: 400)
            #endif
            .padding()
        }
        .batchDeleteBar(
            isShown: isSelectingMonths,
            selectedCount: selectedMonths.count,
            deleteTitle: String(localized: "Delete \(selectedMonths.count) Months"),
            reviewSections: monthReviewSections,
            onDelete: deleteSelectedMonths
        )
        #if os(macOS)
        .navigationSplitViewColumnWidth(min: 200, ideal: 300, max: 350)
        #endif
        #if os(iOS) || DEBUG
        .toolbar {
            #if os(iOS)
            ToolbarItem {
                Button("Settings", systemImage: "gearshape") {
                    isShowingSettings = true
                }
            }
            #endif
            #if DEBUG
            if !StoreCapture.isEnabled {
                ToolbarItem {
                    Button("Debug", systemImage: "ladybug") {
                        isShowingDebugMenu = true
                    }
                }
            }
            #endif
        }
        #endif
        #if os(iOS)
        .sheet(isPresented: $isShowingSettings) {
            SettingsView()
        }
        #endif
        #if DEBUG
        .sheet(isPresented: $isShowingDebugMenu) {
            DebugMenuView()
        }
        #endif
    }

    private var archivedMonths: ArraySlice<Month> {
        months.dropFirst()
    }

    private var isSelectingMonths: Bool {
        monthSelection.isActive && !archivedMonths.isEmpty
    }

    private var selectedMonths: [Month] {
        monthSelection.selected(in: Array(archivedMonths))
    }

    private func monthReviewSections() -> [BatchDeleteReviewSheet.Section] {
        [
            .willBeDeleted(
                selectedMonths.map { month in .init(title: month.name, transactionCount: month.transactionGroups.count) },
                note: String(localized: "Their notes and images go too.")
            ),
            .stays([
                .init(title: String(localized: "Recurring Transactions"), detail: "\(recurringRules.count { !$0.hasEnded })"),
                .init(title: String(localized: "Other months"), detail: "\(months.count - selectedMonths.count)")
            ])
        ]
    }

    private func deleteSelectedMonths() {
        onDeleteMonths(selectedMonths)
        monthSelection.end()
    }

    private var selectedMonth: Binding<Month?> {
        Binding(
            get: {
                guard case .month(let month) = selection else { return nil }
                return month
            },
            set: { selection = $0.map(SidebarSelection.month) }
        )
    }
}

private extension View {
    func inactive(_ isInactive: Bool) -> some View {
        disabled(isInactive)
            .opacity(isInactive ? 0.4 : 1)
    }
}
