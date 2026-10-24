//
//  TransactionExportImage.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 24/10/2026.
//

import Foundation
import SwiftData

enum TransactionExportImage {
    static let folderName = "Images"

    private static let maximumTitleLength = 60
    private static let fallbackTitle = "Transaction"
    private static let forbiddenCharacters = CharacterSet(charactersIn: "/\\:*?\"<>|").union(.newlines)
    private static let heicBrands: Set<String> = ["ftypheic", "ftypheix", "ftypmif1", "ftyphevc"]

    static func fileName(
        date: Date,
        title: String,
        transactionID: UUID,
        data: Data,
        timeZone: TimeZone = .current
    ) -> String {
        let day = TransactionCSVBuilder.dayText(for: date, timeZone: timeZone)
        let shortID = transactionID.uuidString.prefix(8)
        return "\(day) \(sanitizedTitle(title)) \(shortID).\(fileExtension(for: data))"
    }

    static func relativePath(forFileName fileName: String) -> String {
        "\(folderName)/\(fileName)"
    }

    static func sanitizedTitle(_ title: String) -> String {
        let collapsed = title
            .components(separatedBy: forbiddenCharacters)
            .joined(separator: "-")
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
        let capped = String(collapsed.prefix(maximumTitleLength)).trimmingCharacters(in: .whitespaces)
        return capped.isEmpty ? fallbackTitle : capped
    }

    static func fileExtension(for data: Data) -> String {
        let bytes = [UInt8](data.prefix(12))
        if bytes.starts(with: [0xFF, 0xD8, 0xFF]) {
            return "jpg"
        }
        if bytes.starts(with: [0x89, 0x50, 0x4E, 0x47]) {
            return "png"
        }
        if bytes.count == 12, heicBrands.contains(String(decoding: bytes[4...], as: UTF8.self)) {
            return "heic"
        }
        return "jpg"
    }

    static func rowsWithImages(in rows: [TransactionExportRow]) -> [TransactionExportRow] {
        var seenTransactionIDs: Set<UUID> = []
        return rows.filter { row in
            row.imageSourceID != nil && seenTransactionIDs.insert(row.transactionID).inserted
        }
    }

    @MainActor
    static func writeImages(
        of rows: [TransactionExportRow],
        to folder: URL,
        from container: ModelContainer
    ) throws -> [UUID: String] {
        let context = ModelContext(container)
        var paths: [UUID: String] = [:]
        for row in rowsWithImages(in: rows) {
            guard let sourceID = row.imageSourceID, let data = try imageData(for: sourceID, in: context) else {
                continue
            }
            let imageFileName = fileName(date: row.date, title: row.title, transactionID: row.transactionID, data: data)
            try data.write(to: folder.appending(path: imageFileName, directoryHint: .notDirectory), options: .atomic)
            paths[row.transactionID] = relativePath(forFileName: imageFileName)
        }
        return paths
    }

    @MainActor
    private static func imageData(for sourceID: PersistentIdentifier, in context: ModelContext) throws -> Data? {
        var descriptor = FetchDescriptor<TransactionGroup>(predicate: #Predicate { group in group.persistentModelID == sourceID })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first?.imageAttachmentData
    }
}
