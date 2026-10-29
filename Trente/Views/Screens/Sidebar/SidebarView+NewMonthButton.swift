//
//  SidebarView+NewMonthButton.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 22/04/2025.
//

import SwiftUI
import SwiftData

extension SidebarView {
    struct NewMonthButton: View {
        @Environment(\.openWindow) private var openWindow
        @State private var isShowingNewMonthSheet = false

        var body: some View {
            Button {
                #if os(macOS)
                openWindow(id: WindowIdentifiers.newMonth)
                #else
                isShowingNewMonthSheet = true
                #endif
            } label: {
                Label("Start a New Month", systemImage: "calendar.badge.plus")
            }
            .buttonStyle(TrenteSecondaryButtonStyle())
            .sheet(isPresented: $isShowingNewMonthSheet) {
                NewMonthView()
            }
        }
    }
}
