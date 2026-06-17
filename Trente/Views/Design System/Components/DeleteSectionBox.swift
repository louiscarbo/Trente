//
//  DeleteSectionBox.swift
//  Trente
//

import SwiftUI

struct DeleteSectionBox: View {
    var title: String
    var onDelete: () -> Void

    @State private var showConfirmation = false

    var body: some View {
        let warning = String(localized: "This action cannot be undone.")
        GroupBox(label: Label(title, systemImage: "trash.fill")) {
            VStack(spacing: .medium) {
                Text(warning)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundStyle(.secondary)
                Button(role: .destructive) {
                    showConfirmation = true
                } label: {
                    Label(title, systemImage: "trash.fill")
                        .font(.headline)
                }
                .buttonStyle(TrentePrimaryButtonStyle(narrow: true))
                .confirmationDialog(String(localized: "Are you sure?"), isPresented: $showConfirmation, titleVisibility: .visible) {
                    Button(String(localized: "Delete"), role: .destructive, action: onDelete)
                    Button(String(localized: "Cancel"), role: .cancel) {}
                } message: {
                    Text(warning)
                }
            }
        }
        .groupBoxStyle(TrenteGroupBoxStyle())
    }
}
