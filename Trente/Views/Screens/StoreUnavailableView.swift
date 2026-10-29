//
//  StoreUnavailableView.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 22/10/2026.
//

import SwiftUI

struct StoreUnavailableView: View {
    let errorDetails: String

    var body: some View {
        ContentUnavailableView {
            Label("Your budget couldn't be opened", systemImage: "externaldrive.badge.exclamationmark")
        } description: {
            Text("Your data has not been deleted. Try updating Trente, and share the error details if the problem persists.")
        } actions: {
            ShareLink(item: errorDetails) {
                Label("Share error details", systemImage: "square.and.arrow.up")
            }
            .buttonStyle(TrentePrimaryButtonStyle(narrow: true))
            .frame(maxWidth: 300)
        }
    }
}

#Preview {
    StoreUnavailableView(errorDetails: "SwiftDataError(_error: SwiftData.SwiftDataError._Error.loadIssueModelContainer)")
}
