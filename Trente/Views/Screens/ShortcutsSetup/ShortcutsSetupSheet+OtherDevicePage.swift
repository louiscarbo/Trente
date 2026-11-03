//
//  ShortcutsSetupSheet+OtherDevicePage.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 03/11/2026.
//

import SwiftUI

extension ShortcutsSetupSheet {
    struct OtherDevicePage: View {
        var body: some View {
            ContentUnavailableView {
                Label("Set this up on your iPhone", systemImage: "iphone")
            } description: {
                Text(
                    """
                    Apple Pay purchases reach Trente through an automation in the Shortcuts app on your iPhone. \
                    Open Trente there, go to Settings and tap Connect Trente to Apple Pay.
                    """
                )
            }
        }
    }
}

#Preview {
    ShortcutsSetupSheet.OtherDevicePage()
}
