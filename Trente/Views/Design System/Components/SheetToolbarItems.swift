//
//  SheetToolbarItems.swift
//  Trente
//

import SwiftUI

struct CloseToolbarItem: ToolbarContent {
    let action: () -> Void

    var body: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            #if os(iOS)
            Button("Close", systemImage: "chevron.down", action: action)
            #else
            Button("Close", role: .close, action: action)
            #endif
        }
    }
}

struct CancelToolbarItem: ToolbarContent {
    var systemImage: String = "xmark"
    let action: () -> Void

    var body: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            #if os(iOS)
            Button("Cancel", systemImage: systemImage, role: .cancel, action: action)
            #else
            Button("Cancel", role: .cancel, action: action)
            #endif
        }
    }
}

struct ConfirmToolbarItem: ToolbarContent {
    var title: LocalizedStringKey = "Done"
    var isDisabled: Bool = false
    let action: () -> Void

    var body: some ToolbarContent {
        ToolbarItem(placement: .confirmationAction) {
            Group {
                #if os(iOS)
                Button(title, systemImage: "checkmark", role: .confirm, action: action)
                #else
                Button(title, role: .confirm, action: action)
                #endif
            }
            .disabled(isDisabled)
        }
    }
}

struct EditToolbarItem: ToolbarContent {
    let action: () -> Void

    var body: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            #if os(iOS)
            Button("Edit", systemImage: "pencil", action: action)
            #else
            Button("Edit", action: action)
            #endif
        }
    }
}
