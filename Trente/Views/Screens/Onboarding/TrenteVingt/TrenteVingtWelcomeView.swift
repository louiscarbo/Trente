//
//  TrenteVingtWelcomeView.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 03/11/2026.
//

import SwiftData
import SwiftUI

struct TrenteVingtWelcomeView: View {
    let export: TrenteVingtExport
    let onImported: () -> Void
    let onStartFresh: () -> Void

    @Environment(\.modelContext) private var modelContext
    @State private var skipNote: String?
    @State private var errorMessage: String?

    var body: some View {
        OnboardingStepLayout(compactArrangement: .secondaryBelow) {
            VStack(spacing: .large) {
                StickerView(imageName: "Trente Pig Sticker", rotation: .zero)
                    .frame(width: 170)
                OnboardingHeader(
                    title: "Welcome from TrenteVingt!",
                    subtitle: """
                        We found your TrenteVingt budget on this iPhone: ^[\(export.months.count) month](inflect: true) and \
                        ^[\(export.transactionCount) transaction](inflect: true). Bring it into Trente to pick up where you left off.
                        """,
                    alignment: .center
                )
            }
        } secondary: {
            EmptyView()
        } actions: {
            OnboardingContinueButton(title: "Import My Data", action: importData)
            Button(action: onStartFresh) {
                Text("Start Fresh")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(TrenteSecondaryButtonStyle())
        }
        .errorAlert("We couldn't import your data", message: $errorMessage)
        .alert("Some data wasn't imported", item: $skipNote) { _ in
            Button("OK", action: onImported)
        } message: { note in
            Text(note)
        }
    }

    private func importData() {
        do {
            let summary = try TrenteVingtImporter().importData(export, into: modelContext)
            if let note = summary.skipNote {
                skipNote = note
            } else {
                onImported()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
