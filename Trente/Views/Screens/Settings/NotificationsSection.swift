//
//  NotificationsSection.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 24/10/2026.
//

import SwiftUI

struct NotificationsSection: View {
    let status: NotificationPermissionStatus?
    @Binding var reminderTime: Date
    let mentionsApplePay: Bool
    let onTurnOn: () -> Void
    let onOpenSettings: () -> Void

    var body: some View {
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
                Button("Notification Settings", systemImage: "gear", action: onOpenSettings)
            }
            DatePicker(
                "Reminder Time",
                selection: $reminderTime,
                displayedComponents: .hourAndMinute
            )
            .disabled(status != .authorized)
        } header: {
            Text("Notifications")
        } footer: {
            if mentionsApplePay {
                Text("""
                    Trente reminds you at this time when a new month starts and when a recurring transaction is due. \
                    Apple Pay notifications arrive right after each purchase.
                    """)
            } else {
                Text("Trente reminds you at this time when a new month starts and when a recurring transaction is due.")
            }
        }
    }
}

#Preview {
    Form {
        NotificationsSection(
            status: .notDetermined,
            reminderTime: .constant(.now),
            mentionsApplePay: true,
            onTurnOn: {},
            onOpenSettings: {}
        )
        NotificationsSection(
            status: .authorized,
            reminderTime: .constant(.now),
            mentionsApplePay: false,
            onTurnOn: {},
            onOpenSettings: {}
        )
    }
    .formStyle(.grouped)
}
