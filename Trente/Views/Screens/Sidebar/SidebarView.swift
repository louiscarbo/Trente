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
}

struct SidebarView: View {
    let months: [Month]
    @Binding var selection: SidebarSelection?

    @Query private var recurringRules: [RecurringTransactionRule]

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

                    MonthSummaryCard(
                        name: currentMonth.name,
                        remaining: currentMonth.remainingAmount,
                        spent: currentMonth.spentAmount(in: .all),
                        currencyCode: currentMonth.currency.isoCode,
                        isOverspent: currentMonth.overSpent,
                        isSelected: selectedMonth.wrappedValue == currentMonth
                    ) {
                        withAnimation(.easeOut) {
                            selectedMonth.wrappedValue = currentMonth
                        }
                    }
                }

                NewMonthButton()
                    .padding(.vertical)

                if !months.isEmpty {
                    Text("RECURRING")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                    RecurringTransactionsRowView(
                        activeCount: recurringRules.count { !$0.hasEnded },
                        isSelected: selection == .recurring
                    ) {
                        selection = .recurring
                    }
                    .padding(.bottom)
                }

                if months.count > 1 {
                    Text("ARCHIVED MONTHS")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                    ArchivedMonthsList(selectedMonth: selectedMonth, archivedMonths: months.dropFirst())
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
            ToolbarItem {
                Button("Debug", systemImage: "ladybug") {
                    isShowingDebugMenu = true
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
