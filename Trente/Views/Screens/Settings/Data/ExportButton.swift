//
//  ExportButton.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 23/10/2026.
//

import SwiftUI

struct ExportButton: View {
    let title: LocalizedStringKey
    let file: TransactionsCSVFile

    #if os(macOS)
    @State private var isShowingFileExporter = false
    @State private var exportError: (any Error)?
    @State private var isShowingError = false
    #endif

    var body: some View {
        #if os(iOS)
        ShareLink(item: file, preview: SharePreview(file.fileNameWithExtension)) {
            Label(title, systemImage: "square.and.arrow.up")
        }
        .buttonStyle(TrentePrimaryButtonStyle(narrow: true))
        #else
        Button {
            isShowingFileExporter = true
        } label: {
            Label(title, systemImage: "square.and.arrow.up")
        }
        .buttonStyle(TrentePrimaryButtonStyle(narrow: true))
        .fileExporter(
            isPresented: $isShowingFileExporter,
            item: file,
            contentTypes: [file.contentType],
            defaultFilename: file.fileName
        ) { result in
            if case .failure(let error) = result {
                exportError = error
                isShowingError = true
            }
        }
        .alert("Export Failed", isPresented: $isShowingError, presenting: exportError) { _ in
        } message: { error in
            Text(error.localizedDescription)
        }
        #endif
    }
}

#Preview {
    ExportButton(title: "Export…", file: TransactionsCSVFile(monthIDs: [], fileName: "Trente 2026-10"))
        .padding()
}
