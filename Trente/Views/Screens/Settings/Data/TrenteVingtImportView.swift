//
//  TrenteVingtImportView.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 03/11/2026.
//

import SwiftData
import SwiftUI

struct TrenteVingtImportView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var export: TrenteVingtExport?
    @State private var summary = TrenteVingtImportSummary()
    @State private var hasImported = false
    @State private var isChoosingFile = false
    @State private var errorMessage: String?

    var body: some View {
        Form {
            Section {
                if hasImported || !summary.isEmpty {
                    LabeledContent("Months", value: summary.monthCount, format: .number)
                    LabeledContent("Transactions", value: summary.transactionCount, format: .number)
                    LabeledContent("Recurring Transactions", value: summary.recurringTransactionCount, format: .number)
                } else {
                    Text(emptyMessage)
                        .foregroundStyle(.secondary)
                }
                if !hasImported, !summary.isEmpty {
                    Button("Import", action: importData)
                }
            } header: {
                Text(hasImported ? "Imported" : "From TrenteVingt")
            } footer: {
                if let skipNote = summary.skipNote {
                    Text(skipNote)
                }
            }

            Section {
                Button("Choose Export File…") {
                    isChoosingFile = true
                }
            } footer: {
                Text("In TrenteVingt, open Settings and tap Export for Trente. Save the file or send it to this device, then choose it here.")
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Import from TrenteVingt")
        .inlineNavigationBarTitleDisplayMode()
        .fileImporter(isPresented: $isChoosingFile, allowedContentTypes: [.json], onCompletion: loadFile)
        .errorAlert("We couldn't import your data", message: $errorMessage)
        .onAppear {
            guard export == nil, let snapshot = TrenteVingtSnapshot.load() else { return }
            select(snapshot)
        }
    }

    private var emptyMessage: LocalizedStringKey {
        export == nil
            ? "Open TrenteVingt on this device to find your data here, or choose an export file."
            : "There's nothing new to import."
    }

    private func select(_ newExport: TrenteVingtExport) {
        do {
            summary = try TrenteVingtImporter().preview(of: newExport, in: modelContext)
            export = newExport
            hasImported = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func loadFile(_ result: Result<URL, any Error>) {
        do {
            select(try TrenteVingtSnapshot.load(fromFileAt: result.get()))
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func importData() {
        guard let export else { return }
        do {
            summary = try TrenteVingtImporter().importData(export, into: modelContext)
            hasImported = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        TrenteVingtImportView()
    }
    .modelContainer(DataProvider.shared.modelContainer)
}
