//
//  MonthListView.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 22/04/2025.
//

import SwiftUI
import SwiftData

struct MonthListView: View {
    @Query(
        sort: \Month.startDate,
        order: .reverse,
        animation: .default
    ) private var months: [Month]
    @Query private var recurringRules: [RecurringTransactionRule]

    @State private var selection: SidebarSelection?
    @State private var isShowingNewMonth = false
    @State private var pendingTransactionRouter = PendingTransactionRouter.shared
    #if DEBUG
    @State private var isShowingDebugMenu = false
    #endif

    @Environment(\.colorScheme) var colorScheme
    private var lightMode: Bool { colorScheme == .light }

    var body: some View {
        NavigationSplitView {
            ScrollView {
                LazyVStack(alignment: .leading) {
                    if let currentMonth = months.first {
                        Text("CURRENT MONTH")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                        
                        CurrentMonthRowView(currentMonth: currentMonth, selectedMonth: selectedMonth)
                    }

                    // New Month Button
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
            .navigationDestination(item: $selection) { destination in
                destinationView(for: destination)
            }
            #if DEBUG
            .toolbar {
                ToolbarItem {
                    Button("Debug", systemImage: "ladybug") {
                        isShowingDebugMenu = true
                    }
                }
            }
            .sheet(isPresented: $isShowingDebugMenu) {
                DebugMenuView()
            }
            #endif
        } detail: {
            if months.isEmpty {
                ContentUnavailableView {
                    Label("No months available", systemImage: "calendar")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
            } else {
                if let selection {
                    destinationView(for: selection)
                } else {
                    Text("Select a month")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .onAppear {
            selection = months.first.map(SidebarSelection.month)
        }
        .onChange(of: months) { oldMonths, newMonths in
            followLatestMonthIfNeeded(previousLatestMonth: oldMonths.first, newMonths: newMonths)
        }
        .sheet(isPresented: isShowingPendingTransaction) {
            if let id = pendingTransactionRouter.presentedPendingTransactionID {
                PendingTransactionReviewLoader(id: id)
                    .id(id)
            }
        }
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

    @ViewBuilder
    private func destinationView(for destination: SidebarSelection) -> some View {
        switch destination {
        case .month(let month):
            MonthView(month: month)
                .id(month)
        case .recurring:
            if let currency = months.first?.currency {
                RecurringTransactionsListView(currency: currency)
            }
        }
    }

    private func followLatestMonthIfNeeded(previousLatestMonth: Month?, newMonths: [Month]) {
        guard let latestMonth = newMonths.first else { return }
        let selectedMonthID: UUID?
        let isShowingOtherScreen: Bool
        switch selection {
        case .month(let month):
            selectedMonthID = month.id
            isShowingOtherScreen = false
        case .recurring:
            selectedMonthID = nil
            isShowingOtherScreen = true
        case nil:
            selectedMonthID = nil
            isShowingOtherScreen = false
        }
        let shouldFollow = LatestMonthFollowRule.shouldSelectLatestMonth(
            selectedMonthID: selectedMonthID,
            isShowingOtherScreen: isShowingOtherScreen,
            previousLatestMonthID: previousLatestMonth?.id,
            remainingMonthIDs: Set(newMonths.map(\.id))
        )
        if shouldFollow {
            selection = .month(latestMonth)
        }
    }

    private var isShowingPendingTransaction: Binding<Bool> {
        Binding(
            get: { pendingTransactionRouter.presentedPendingTransactionID != nil },
            set: { if !$0 { pendingTransactionRouter.presentedPendingTransactionID = nil } }
        )
    }
}

private enum SidebarSelection: Hashable {
    case month(Month)
    case recurring
}

#Preview {
    MonthListView()
}

struct ArchivedMonthsList: View {
    @Binding var selectedMonth: Month?
    var archivedMonths: ArraySlice<Month>
    
    @Environment(\.colorScheme) var colorScheme
    private var lightMode: Bool { colorScheme == .light }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(archivedMonths) { month in
                MonthRowView(month: month, archivedMonths: archivedMonths, selectedMonth: $selectedMonth)
            }
        }
        .background(
            TrenteListBackgroundView()
        )
   }
}

private struct MonthRowView: View {
    var month: Month
    var archivedMonths: ArraySlice<Month>
    @Binding var selectedMonth: Month?
    
    var isSelected: Bool {
        selectedMonth == month
    }
    @State var isPressed: Bool = false
    
    @Environment(\.colorScheme) var colorScheme
    private var lightMode: Bool { colorScheme == .light }
    
    var body: some View {
        HStack {
            Text(month.name)
            Spacer()
            Text(month.overSpent ? "Over Budget" : "Under Budget")
            Image(systemName: "chevron.right")
                .foregroundStyle(Color.secondary)
        }
        .padding()
        .overlay {
            ZStack {
                if isSelected {
                    if month != archivedMonths.last && month != archivedMonths.first {
                        Rectangle()
                            .stroke(lightMode ? Color.black.opacity(0.5) : Color.white.opacity(0.5), lineWidth: 3)
                    } else if month == archivedMonths.first {
                        UnevenRoundedRectangle(
                            topLeadingRadius: DesignSystem.Radius.large.rawValue,
                            bottomLeadingRadius: 0,
                            bottomTrailingRadius: 0,
                            topTrailingRadius: DesignSystem.Radius.large.rawValue
                        )
                        .stroke(lightMode ? Color.black.opacity(0.5) : Color.white.opacity(0.5), lineWidth: 3)
                    } else {
                        UnevenRoundedRectangle(
                            topLeadingRadius: 0,
                            bottomLeadingRadius: DesignSystem.Radius.large.rawValue,
                            bottomTrailingRadius: DesignSystem.Radius.large.rawValue,
                            topTrailingRadius: 0
                        )
                        .stroke(lightMode ? Color.black.opacity(0.5) : Color.white.opacity(0.5), lineWidth: 3)
                    }
                }
                if isPressed {
                    if month != archivedMonths.last && month != archivedMonths.first {
                        Rectangle()
                            .fill(lightMode ? Color.black.opacity(0.1) : Color.white.opacity(0.1))
                    } else if month == archivedMonths.first {
                        UnevenRoundedRectangle(
                            topLeadingRadius: DesignSystem.Radius.large.rawValue,
                            bottomLeadingRadius: 0,
                            bottomTrailingRadius: 0,
                            topTrailingRadius: DesignSystem.Radius.large.rawValue
                        )
                        .fill(lightMode ? Color.black.opacity(0.1) : Color.white.opacity(0.1))
                    } else {
                        UnevenRoundedRectangle(
                            topLeadingRadius: 0,
                            bottomLeadingRadius: DesignSystem.Radius.large.rawValue,
                            bottomTrailingRadius: DesignSystem.Radius.large.rawValue,
                            topTrailingRadius: 0
                        )
                        .fill(lightMode ? Color.black.opacity(0.1) : Color.white.opacity(0.1))
                    }
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            toggleSelection()
        }
        .onLongPressGesture(
            minimumDuration: 0,
            pressing: { inProgress in
                withAnimation(.easeOut) {
                    isPressed = inProgress
                }
            },
            perform: { }
        )
        
        if month != archivedMonths.last {
            Divider()
        }
    }
    
    func toggleSelection() {
        withAnimation {
            selectedMonth = month
        }
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

struct TrenteListBackgroundView: View {
    @Environment(\.colorScheme) var colorScheme
    private var lightMode: Bool { colorScheme == .light }
    
    var body: some View {
        RoundedRectangle(cornerRadius: DesignSystem.Radius.large.rawValue)
            .foregroundStyle(.regularMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.large.rawValue)
                    .stroke(
                        lightMode ? Color.black.opacity(0.2) : Color.white.opacity(0.2), lineWidth: 3)
            )
    }
}
