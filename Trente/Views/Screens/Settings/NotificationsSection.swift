//
//  NotificationsSection.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 24/10/2026.
//

import SwiftUI

struct NotificationsSection: View {
    let status: NotificationPermissionStatus?
    @Binding var remindsRecurringTransactions: Bool
    @Binding var announcesNewMonths: Bool
    @Binding var reminderTime: Date
    let mentionsApplePay: Bool
    let onTurnOn: () -> Void
    let onOpenSettings: () -> Void

    var body: some View {
        Section {
            NavigationLink {
                NotificationSettingsView(
                    status: status,
                    remindsRecurringTransactions: $remindsRecurringTransactions,
                    announcesNewMonths: $announcesNewMonths,
                    reminderTime: $reminderTime,
                    mentionsApplePay: mentionsApplePay,
                    onTurnOn: onTurnOn,
                    onOpenSettings: onOpenSettings
                )
            } label: {
                LabeledContent {
                    statusText
                } label: {
                    Label("Notifications", systemImage: "bell")
                }
            }
        }
    }

    @ViewBuilder
    private var statusText: some View {
        switch status {
        case .none:
            EmptyView()
        case .some(.notDetermined), .some(.denied):
            Text("Off")
        case .some(.authorized):
            Text("On")
        }
    }
}

#Preview {
    NavigationStack {
        Form {
            NotificationsSection(
                status: .authorized,
                remindsRecurringTransactions: .constant(true),
                announcesNewMonths: .constant(true),
                reminderTime: .constant(.now),
                mentionsApplePay: true,
                onTurnOn: {},
                onOpenSettings: {}
            )
        }
        .formStyle(.grouped)
    }
}
