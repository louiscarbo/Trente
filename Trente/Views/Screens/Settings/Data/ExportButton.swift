//
//  ExportButton.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 23/10/2026.
//

import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct ExportButton: View {
    let title: LocalizedStringKey
    let file: TransactionsCSVFile

    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @State private var isWriting = false
    @State private var writtenFile: URL?
    @State private var isShowingWrittenFile = false
    @State private var exportError: (any Error)?
    @State private var isShowingError = false

    var body: some View {
        Button(action: export) {
            Label(title, systemImage: "square.and.arrow.up")
                .opacity(isWriting ? 0 : 1)
                .overlay {
                    if isWriting {
                        ProgressView()
                            .tint(colorScheme == .light ? .white : .black)
                    }
                }
        }
        .buttonStyle(TrentePrimaryButtonStyle(narrow: true))
        #if os(iOS)
        .sheet(isPresented: $isShowingWrittenFile) {
            if let writtenFile {
                ShareSheet(url: writtenFile) {
                    isShowingWrittenFile = false
                }
                .presentationDetents([.medium, .large])
                .ignoresSafeArea()
            }
        }
        #else
        .fileExporter(
            isPresented: $isShowingWrittenFile,
            item: writtenFile.map(WrittenFile.init(url:)),
            contentTypes: [writtenFile.map(WrittenFile.contentType(of:)) ?? .commaSeparatedText],
            defaultFilename: file.fileName
        ) { result in
            if case .failure(let error) = result {
                show(error)
            }
        }
        #endif
        .alert("Export Failed", isPresented: $isShowingError, presenting: exportError) { _ in
        } message: { error in
            Text(error.localizedDescription)
        }
    }

    private func export() {
        guard !isWriting else { return }
        isWriting = true
        let container = modelContext.container
        Task {
            defer { isWriting = false }
            do {
                try modelContext.save()
                writtenFile = try await file.write(from: container)
                isShowingWrittenFile = true
            } catch {
                show(error)
            }
        }
    }

    private func show(_ error: any Error) {
        exportError = error
        isShowingError = true
    }
}

#if !os(iOS)
private struct WrittenFile: Transferable {
    let url: URL

    static func contentType(of url: URL) -> UTType {
        url.pathExtension == "zip" ? .zip : .commaSeparatedText
    }

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .zip) { file in SentTransferredFile(file.url) }
            .suggestedFileName { file in file.url.lastPathComponent }
            .exportingCondition { file in contentType(of: file.url) == .zip }

        FileRepresentation(exportedContentType: .commaSeparatedText) { file in SentTransferredFile(file.url) }
            .suggestedFileName { file in file.url.lastPathComponent }
            .exportingCondition { file in contentType(of: file.url) == .commaSeparatedText }
    }
}
#endif

#Preview {
    ExportButton(title: "Export…", file: TransactionsCSVFile(monthIDs: [], fileName: "Trente 2026-10"))
        .padding()
}
