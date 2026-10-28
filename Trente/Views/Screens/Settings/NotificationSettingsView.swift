//
//  NotificationSettingsView.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 24/10/2026.
//

import SwiftUI

struct NotificationSettingsView: View {
    let status: NotificationPermissionStatus?
    @Binding var remindsRecurringTransactions: Bool
    @Binding var announcesNewMonths: Bool
    @Binding var reminderTime: Date
    let mentionsApplePay: Bool
    let onTurnOn: () -> Void
    let onOpenSettings: () -> Void

    var body: some View {
        Form {
            Section {
                switch status {
                case .none:
                    ProgressView()
                        .frame(maxWidth: .infinity)
                case .some(.notDetermined):
                    Button("Turn On Notifications", systemImage: "bell.badge", action: onTurnOn)
                case .some(.denied):
                    LabeledContent("Status") {
                        Text("Off")
                    }
                    Button("Open Settings", systemImage: "gear", action: onOpenSettings)
                case .some(.authorized):
                    LabeledContent("Status") {
                        Text("On")
                    }
                    Button(action: onOpenSettings) {
                        ExternalLinkLabel(title: "Notification Settings", systemImage: "gear")
                    }
                }
            } footer: {
                if let statusFooter {
                    Text(statusFooter)
                }
            }

            if status == .authorized {
                Section {
                    Toggle("Recurring Transactions", systemImage: "repeat", isOn: $remindsRecurringTransactions)
                    Toggle("New Month", systemImage: "calendar", isOn: $announcesNewMonths)
                    DatePicker(
                        "Reminder Time",
                        selection: $reminderTime,
                        displayedComponents: .hourAndMinute
                    )
                    .disabled(!usesReminderTime)
                } header: {
                    Text("Reminders")
                } footer: {
                    Text(remindersFooter)
                }

                if mentionsApplePay {
                    Section {
                        LabeledContent {
                            Text("After Each Purchase")
                        } label: {
                            Label("Apple Pay", systemImage: "wallet.pass")
                        }
                    } footer: {
                        Text("""
                        These come from your Apple Pay automation in the Shortcuts app. \
                        To stop them, turn off or delete that automation.
                        """)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Notifications")
    }

    private var usesReminderTime: Bool {
        NotificationPreferences(
            remindsRecurringTransactions: remindsRecurringTransactions,
            announcesNewMonths: announcesNewMonths
        )
        .usesReminderTime
    }

    private var statusFooter: LocalizedStringKey? {
        switch status {
        case .none, .some(.authorized):
            nil
        case .some(.notDetermined), .some(.denied):
            if mentionsApplePay {
                """
                Get a reminder when a new month starts and when a recurring transaction is due, \
                and a notification after each Apple Pay purchase.
                """
            } else {
                "Get a reminder when a new month starts and when a recurring transaction is due."
            }
        }
    }

    private var remindersFooter: LocalizedStringKey {
        switch (remindsRecurringTransactions, announcesNewMonths) {
        case (true, true):
            "Trente reminds you at this time when a new month starts and when a recurring transaction is due."
        case (true, false):
            "Trente reminds you at this time when a recurring transaction is due."
        case (false, true):
            "Trente reminds you at this time when a new month starts."
        case (false, false):
            "Turn on a reminder to choose when Trente notifies you."
        }
    }
}

#Preview {
    NavigationStack {
        NotificationSettingsView(
            status: .authorized,
            remindsRecurringTransactions: .constant(true),
            announcesNewMonths: .constant(false),
            reminderTime: .constant(.now),
            mentionsApplePay: true,
            onTurnOn: {},
            onOpenSettings: {}
        )
    }
}
