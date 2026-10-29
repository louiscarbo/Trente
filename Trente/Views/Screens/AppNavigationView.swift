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
    @Environment(\.openSettings) private var openSettings
    #else
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
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
    @State private var paywallRouter = PaywallRouter.shared
    #if os(iOS)
    @State private var deepLinkedTransaction: NewTransactionContext?
    #endif

    var body: some View {
        NavigationSplitView(preferredCompactColumn: $preferredCompactColumn) {
            SidebarView(
                months: months,
                selection: sidebarSelection,
                showsSelection: showsSidebarSelection
            )
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
            switch SurfaceStyle.previewScreen {
            case "sidebar", "settings":
                selection = .month(latestMonth)
                #if os(macOS)
                if SurfaceStyle.previewScreen == "settings" {
                    openSettings()
                }
                #endif
            case "newExpense":
                show(.month(latestMonth))
                presentNewTransaction(for: latestMonth)
            default:
                show(.month(latestMonth))
            }
        }
        #if DEBUG
        .task {
            await prepareStoreCapture()
        }
        #endif
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
        .sheet(isPresented: $pendingTransactionRouter.presentedPendingTransactionID.isPresent()) {
            if let id = pendingTransactionRouter.presentedPendingTransactionID {
                PendingTransactionReviewLoader(id: id)
                    .id(id)
            }
        }
        .sheet(isPresented: $paywallRouter.isPresentingPaywall) {
            SubscriptionView()
        }
        #if os(iOS)
        .sheet(item: $deepLinkedTransaction) { context in
            NewTransactionView(context: context)
        }
        #endif
        .transactionActionsErrorAlert()
        .reviewPrompt(
            monthCount: months.count,
            isShowingLatestMonth: isShowingLatestMonth,
            isPresentingSheet: isPresentingSheet
        )
    }

    private var showsSidebarSelection: Bool {
        #if os(macOS)
        true
        #else
        horizontalSizeClass != .compact
        #endif
    }

    private var isShowingLatestMonth: Bool {
        guard let latestMonth = months.first else { return false }
        return selection == .month(latestMonth)
    }

    private var isPresentingSheet: Bool {
        #if os(iOS)
        pendingTransactionRouter.presentedPendingTransactionID != nil
            || paywallRouter.isPresentingPaywall
            || deepLinkedTransaction != nil
        #else
        pendingTransactionRouter.presentedPendingTransactionID != nil || paywallRouter.isPresentingPaywall
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
            if SurfaceStyle.previewScreen == "editMonth" {
                MonthDetailsView(month: month)
            } else {
                MonthView(month: month)
                    .id(month)
            }
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

    #if DEBUG
    private func prepareStoreCapture() async {
        guard StoreCapture.isEnabled else { return }
        #if os(macOS)
        NSApp.appearance = NSAppearance(named: StoreCapture.isDark ? .darkAqua : .aqua)
        if let window = NSApp.windows.first(where: \.isVisible) {
            window.setFrame(NSRect(origin: window.frame.origin, size: StoreCapture.macWindowSize), display: true)
            window.center()
        }
        #endif
        try? await Task.sleep(for: .seconds(1))
        selection = nil
        try? await Task.sleep(for: .milliseconds(300))
        if let latestMonth = months.first {
            show(.month(latestMonth))
        }
    }
    #endif
}

#Preview {
    AppNavigationView(pendingDeepLink: .constant(nil))
}
