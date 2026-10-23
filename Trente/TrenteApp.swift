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
    let container = TrenteContainer.shared

    init() {
        WalletNotificationService.shared.start()
        WidgetRefresher.shared.start()
    }

    var body: some Scene {
        WindowGroup {
            ModelContainerGate(container: container) {
                RootView()
            }
        }
        .defaultSize(width: 1200, height: 800)

        #if os(macOS)
        WindowGroup("New Transaction", id: WindowIdentifiers.newTransaction, for: NewTransactionContext.self) { $context in
            ModelContainerGate(container: container) {
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
        }
        .defaultSize(width: 500, height: 550)

        WindowGroup("New Month", id: WindowIdentifiers.newMonth) {
            ModelContainerGate(container: container) {
                NewMonthView()
            }
        }
        .defaultSize(width: 500, height: 600)

        Settings {
            SettingsView()
        }
        #endif
    }
}
