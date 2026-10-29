//
//  AppIconSection.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 29/10/2026.
//

import SwiftUI

struct AppIconSection: View {
    @Binding var selection: AppIcon

    var body: some View {
        Section {
            AppIconPicker(selection: $selection)
                .requiresTrentePlus()
        } header: {
            Text("App Icon")
        }
    }
}

#Preview {
    @Previewable @State var selection = AppIcon.green
    @Previewable @State var isSubscribed = false

    Form {
        Toggle("Subscribed", isOn: $isSubscribed)
        AppIconSection(selection: $selection)
    }
    .formStyle(.grouped)
    .environment(\.isTrentePlusSubscribed, isSubscribed)
}
