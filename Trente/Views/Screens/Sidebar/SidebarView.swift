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

                    CurrentMonthRowView(currentMonth: currentMonth, selectedMonth: selectedMonth)
                }

                NewMonthButtonView()
                    .padding(.vertical)

                if !months.isEmpty {
                    Text("RECURRING")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                    RecurringTransactionsRowView(
                        activeCount: recurringRules.filter { !$0.hasEnded }.count,
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

private struct NewMonthButtonView: View {
    @Environment(\.openWindow) private var openWindow
    @State private var isShowingNewMonthSheet = false

    var body: some View {
        Button {
            #if os(macOS)
            openWindow(id: WindowIdentifiers.newMonth)
            #else
            isShowingNewMonthSheet = true
            #endif
        } label: {
            Label("Start a New Month", systemImage: "calendar.badge.plus")
        }
        .buttonStyle(TrenteSecondaryButtonStyle())
        .sheet(isPresented: $isShowingNewMonthSheet) {
            NewMonthView()
        }
    }
}
