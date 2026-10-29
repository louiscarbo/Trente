//
//  ViewUtils.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 22/04/2025.
//

import SwiftUI

extension View {
    /// Applies `.navigationBarTitleDisplayMode(.inline)` on iOS; no-op on macOS, which has no equivalent.
    @ViewBuilder
    func inlineNavigationBarTitleDisplayMode() -> some View {
        #if os(iOS)
        self.navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }
}

// MARK: View Extensions
extension View {
    @ViewBuilder
    func modify<T: View>(@ViewBuilder _ transform: (Self) -> T) -> some View {
        transform(self)
    }

    /// Standard destructive-delete confirmation dialog with a "cannot be undone" warning.
    func deleteConfirmation(
        isPresented: Binding<Bool>,
        message: String = String(localized: "This action cannot be undone."),
        onDelete: @escaping () -> Void
    ) -> some View {
        confirmationDialog(
            String(localized: "Are you sure?"),
            isPresented: isPresented,
            titleVisibility: .visible
        ) {
            Button(String(localized: "Delete"), role: .destructive, action: onDelete)
            Button(String(localized: "Cancel"), role: .cancel) {}
        } message: {
            Text(message)
        }
    }

    func deleteConfirmation<Item>(
        item: Binding<Item?>,
        message: String = String(localized: "This action cannot be undone."),
        onDelete: @escaping (Item) -> Void
    ) -> some View {
        confirmationDialog(
            String(localized: "Are you sure?"),
            item: item,
            titleVisibility: .visible
        ) { presentedItem in
            Button(String(localized: "Delete"), role: .destructive) { onDelete(presentedItem) }
            Button(String(localized: "Cancel"), role: .cancel) {}
        } message: { _ in
            Text(message)
        }
    }
}
