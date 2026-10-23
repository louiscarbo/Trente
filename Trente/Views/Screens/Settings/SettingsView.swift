//
//  SettingsView.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 24/10/2026.
//

import SwiftUI

struct SettingsView: View {
    #if os(iOS)
    @Environment(\.dismiss) private var dismiss
    #endif

    var body: some View {
        NavigationStack {
            Form {
                Section {
                } footer: {
                    AppVersionFooter(versionDescription: AppInfo.current.versionDescription)
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Settings")
            #if os(iOS)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            #endif
        }
        #if os(macOS)
        .frame(minWidth: 460, idealWidth: 500, minHeight: 520)
        #endif
    }
}

#Preview {
    SettingsView()
}
