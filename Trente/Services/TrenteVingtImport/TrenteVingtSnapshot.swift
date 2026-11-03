//
//  TrenteVingtSnapshot.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 03/11/2026.
//

import Foundation

enum TrenteVingtSnapshot {
    private static let importHost = "import-trentevingt"

    static func load() -> TrenteVingtExport? {
        let fileURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: TrentePlusEntitlement.appGroupID)?
            .appending(path: "TrenteVingt/Export.json")
        guard let fileURL, let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? TrenteVingtExport.decode(from: data)
    }

    static func load(fromFileAt url: URL) throws -> TrenteVingtExport {
        let isAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if isAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }
        return try TrenteVingtExport.decode(from: Data(contentsOf: url))
    }

    static func isImportURL(_ url: URL) -> Bool {
        url.scheme?.lowercased() == DeepLink.scheme && url.host(percentEncoded: false)?.lowercased() == importHost
    }
}
