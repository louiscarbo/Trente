//
//  ExportMenu.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 23/10/2026.
//

import SwiftUI

struct ExportMenu: View {
    var rows: [TransactionExportRow]
    var fileName: String

    @State private var isShowingFileExporter = false
    @State private var exportError: Error?

    private var file: TransactionsCSVFile {
        TransactionsCSVFile(rows: rows, fileName: fileName)
    }

    var body: some View {
        Menu {
            ShareLink(item: file, preview: SharePreview(file.fileNameWithExtension)) {
                Label("Share…", systemImage: "square.and.arrow.up")
            }
            Button("Save to File…", systemImage: "square.and.arrow.down") {
                isShowingFileExporter = true
            }
        } label: {
            Label("Export", systemImage: "square.and.arrow.up")
        }
        .disabled(rows.isEmpty)
        .fileExporter(
            isPresented: $isShowingFileExporter,
            item: file,
            contentTypes: [.commaSeparatedText],
            defaultFilename: fileName
        ) { result in
            if case .failure(let error) = result {
                exportError = error
            }
        }
        .alert("Export Failed", isPresented: isShowingError, presenting: exportError) { _ in
        } message: { error in
            Text(error.localizedDescription)
        }
    }

    private var isShowingError: Binding<Bool> {
        Binding(
            get: { exportError != nil },
            set: { if !$0 { exportError = nil } }
        )
    }
}

#Preview {
    ExportMenu(rows: [], fileName: "Trente 2026-10")
}
