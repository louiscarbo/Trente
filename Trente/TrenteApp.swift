//
//  TrenteApp.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 16/04/2025.
//

import SwiftUI
import SwiftData
import WidgetKit

@main
struct TrenteApp: App {
    let container: ModelContainer

    init() {
        #if os(iOS)
        BackgroundRefreshScheduler.registerHandler()
        #endif

        do {
            #if DEBUG
            container = DataProvider.shared.modelContainer
            #else
            container = try AppGroup.makeContainer()
            #endif
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
        .defaultSize(width: 1200, height: 800)

        #if os(macOS)
        WindowGroup("New Transaction", id: WindowIdentifiers.newTransaction, for: NewTransactionContext.self) { $context in
            if let context {
                NewTransactionView(context: context)
            } else {
                ContentUnavailableView(
                    "An error occurred",
                    image: "xmark",
                    description:
                        Text("Please open this window from a month dashboard.")
                )
            }
        }
        .modelContainer(container)
        .defaultSize(width: 500, height: 550)

        WindowGroup("New Month", id: WindowIdentifiers.newMonth) {
            NewMonthView()
        }
        .modelContainer(container)
        .defaultSize(width: 500, height: 600)
        #endif
    }
}

private struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        MonthListView()
            .task {
                await runAutoConfirm()
            }
            .onChange(of: scenePhase) { _, newPhase in
                switch newPhase {
                case .active:
                    Task { await runAutoConfirm() }
                case .background:
                    #if os(iOS)
                    BackgroundRefreshScheduler.schedule()
                    #endif
                default:
                    break
                }
            }
    }

    private func runAutoConfirm() async {
        do {
            let count = try RecurringTransactionService.shared.autoConfirmDueInstances(asOf: .now, in: modelContext)
            if count > 0 {
                WidgetCenter.shared.reloadAllTimelines()
            }
        } catch {
            // Best-effort: silent failure, retried on next activation.
        }
    }
}
