//
//  DeleteSectionBox.swift
//  Trente
//

import SwiftUI

struct DeleteSectionBox: View {
    var title: String
    var message = String(localized: "This action cannot be undone.")
    var onDelete: () -> Void

    @State private var showConfirmation = false

    var body: some View {
        GroupBox(label: Label(title, systemImage: "trash.fill")) {
            VStack(spacing: .medium) {
                Text(message)
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
                .deleteConfirmation(isPresented: $showConfirmation, message: message, onDelete: onDelete)
            }
        }
        .groupBoxStyle(TrenteGroupBoxStyle())
    }
}
