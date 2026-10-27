//
//  AppNavigationView.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 24/10/2026.
//

import SwiftUI
import SwiftData

struct AppNavigationView: View {
    #if os(macOS)
    @Environment(\.openWindow) private var openWindow
    #endif

    @Binding var pendingDeepLink: DeepLink?

    @Query(
        sort: \Month.startDate,
        order: .reverse,
        animation: .default
    ) private var months: [Month]

    @State private var selection: SidebarSelection?
    @State private var preferredCompactColumn: NavigationSplitViewColumn = .sidebar
    @State private var pendingTransactionRouter = PendingTransactionRouter.shared
    #if os(iOS)
    @State private var deepLinkedTransaction: NewTransactionContext?
    #endif

    var body: some View {
        NavigationSplitView(preferredCompactColumn: $preferredCompactColumn) {
            SidebarView(months: months, selection: sidebarSelection)
        } detail: {
            NavigationStack {
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
            .id(selection)
        }
        .onAppear {
            guard selection == nil, let latestMonth = months.first else { return }
            show(.month(latestMonth))
        }
        .onChange(of: pendingDeepLink, initial: true) { _, link in
            openDeepLink(link)
        }
        .onChange(of: months) { oldMonths, newMonths in
            guard let latestMonth = newMonths.first else { return }
            switch selection {
            case .recurring:
                return
            case .month(let month) where month != oldMonths.first && newMonths.contains(month):
                return
            default:
                selection = .month(latestMonth)
            }
        }
        .sheet(isPresented: isShowingPendingTransaction) {
            if let id = pendingTransactionRouter.presentedPendingTransactionID {
                PendingTransactionReviewLoader(id: id)
                    .id(id)
            }
        }
        #if os(iOS)
        .sheet(item: $deepLinkedTransaction) { context in
            NewTransactionView(context: context)
        }
        #endif
        .reviewPrompt(
            monthCount: months.count,
            isShowingLatestMonth: isShowingLatestMonth,
            isPresentingSheet: isPresentingSheet
        )
    }

    private var isShowingLatestMonth: Bool {
        guard let latestMonth = months.first else { return false }
        return selection == .month(latestMonth)
    }

    private var isPresentingSheet: Bool {
        #if os(iOS)
        pendingTransactionRouter.presentedPendingTransactionID != nil || deepLinkedTransaction != nil
        #else
        pendingTransactionRouter.presentedPendingTransactionID != nil
        #endif
    }

    private func openDeepLink(_ link: DeepLink?) {
        guard let link else { return }
        pendingDeepLink = nil
        guard let destination = link.destination(in: months) else { return }
        show(.month(destination.month))
        if destination.opensNewTransaction {
            presentNewTransaction(for: destination.month)
        }
    }

    private func presentNewTransaction(for month: Month) {
        let context = NewTransactionContext(currency: month.currency, monthID: month.persistentModelID)
        #if os(macOS)
        openWindow(id: WindowIdentifiers.newTransaction, value: context)
        #else
        deepLinkedTransaction = context
        #endif
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

    private var sidebarSelection: Binding<SidebarSelection?> {
        Binding(
            get: { selection },
            set: { newSelection in
                guard let newSelection else { return }
                show(newSelection)
            }
        )
    }

    private func show(_ destination: SidebarSelection) {
        selection = destination
        preferredCompactColumn = .detail
    }

    private var isShowingPendingTransaction: Binding<Bool> {
        Binding(
            get: { pendingTransactionRouter.presentedPendingTransactionID != nil },
            set: { if !$0 { pendingTransactionRouter.presentedPendingTransactionID = nil } }
        )
    }
}

#Preview {
    AppNavigationView(pendingDeepLink: .constant(nil))
}
