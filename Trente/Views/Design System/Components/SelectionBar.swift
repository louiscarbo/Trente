//
//  SelectionBar.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 30/10/2026.
//

import SwiftUI

struct SelectionBar: View {
    let selectedCount: Int
    let deleteTitle: String
    let onDelete: () -> Void

    var body: some View {
        Button(selectedCount > 0 ? deleteTitle : String(localized: "Delete"), role: .destructive, action: onDelete)
            .font(.headline)
            .buttonStyle(TrentePrimaryButtonStyle())
            .disabled(selectedCount == 0)
            .padding(.horizontal)
            .padding(.vertical, 8)
    }
}

#Preview {
    SelectionBar(selectedCount: 3, deleteTitle: "Delete 3 Transactions") {}
}
