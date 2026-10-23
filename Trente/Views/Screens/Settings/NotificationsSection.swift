//
//  NotificationsSection.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 24/10/2026.
//

import SwiftUI

struct NotificationsSection: View {
    let status: NotificationPermissionStatus?
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
        } header: {
            Text("Notifications")
        } footer: {
            Text("Trente sends a notification after each Apple Pay purchase so you can log it.")
        }
    }
}

#Preview {
    Form {
        NotificationsSection(status: nil, onTurnOn: {}, onOpenSettings: {})
        NotificationsSection(status: .notDetermined, onTurnOn: {}, onOpenSettings: {})
        NotificationsSection(status: .denied, onTurnOn: {}, onOpenSettings: {})
        NotificationsSection(status: .authorized, onTurnOn: {}, onOpenSettings: {})
    }
    .formStyle(.grouped)
}
