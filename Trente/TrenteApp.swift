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
    let container: Result<ModelContainer, any Error>
    @State private var trentePlus = TrentePlusStatus.shared

    init() {
        CloudSyncMonitor.shared.start()
        TrentePlusStatus.shared.start()
        container = TrenteContainer.shared
        WidgetRefresher.shared.start()
        if case .success(let modelContainer) = container {
            CatchUpService.shared.start(container: modelContainer)
            NotificationDelegate.shared.start(container: modelContainer)
            NotificationScheduler.shared.start(container: modelContainer)
        }
    }

    var body: some Scene {
        WindowGroup {
            ModelContainerGate(container: container) {
                RootView()
            }
            .environment(\.isTrentePlusSubscribed, trentePlus.isSubscribed)
        }
        .defaultSize(width: 1200, height: 800)
        #if os(macOS)
        .commands {
            TrenteHelpCommands()
        }
        #endif

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
            .environment(\.isTrentePlusSubscribed, trentePlus.isSubscribed)
        }
        .defaultSize(width: 500, height: 550)

        WindowGroup("New Month", id: WindowIdentifiers.newMonth) {
            ModelContainerGate(container: container) {
                NewMonthView()
            }
            .environment(\.isTrentePlusSubscribed, trentePlus.isSubscribed)
        }
        .defaultSize(width: 500, height: 600)

        Settings {
            ModelContainerGate(container: container) {
                SettingsView()
            }
            .environment(\.isTrentePlusSubscribed, trentePlus.isSubscribed)
        }

        Window("Trente Help", id: WindowIdentifiers.help) {
            NavigationStack {
                FAQView(
                    items: FAQItem.items(isPhone: false),
                    contactURL: SupportMail.feedbackURL(appInfo: .current),
                    contactAddress: SupportMail.address
                )
            }
        }
        .defaultSize(width: 520, height: 600)
        #endif
    }
}
