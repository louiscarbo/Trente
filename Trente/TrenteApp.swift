//
//  TrenteApp.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 16/04/2025.
//

import SwiftUI
import SwiftData

@main
struct TrenteApp: App {
    let container: ModelContainer

    init() {
        do {
//            #if DEBUG
//            container = DataProvider.shared.modelContainer
//            #else
            let schema = Schema([Month.self])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            container = try ModelContainer(for: schema, configurations: [config])
//            #endif
        } catch {
            // TODO: Maybe fail more gracefully?
            fatalError("Failed to initialize ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            MonthListView()
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
