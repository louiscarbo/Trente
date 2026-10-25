//
//  TransactionCSVFormat.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 24/10/2026.
//

import Foundation

struct TransactionCSVFormat: Hashable, Sendable {
    enum Style: String, CaseIterable, Identifiable, Sendable {
        case standard
        case european

        var id: String { rawValue }

        var title: LocalizedStringResource {
            switch self {
            case .standard:
                "Standard"
            case .european:
                "Excel in French and Other European Languages"
            }
        }
    }

    static let styleKey = "export.style"
    static let includesNotesKey = "export.includesNotes"

    var style: Style = .standard
    var includesNotes = true

    var separator: String {
        switch style {
        case .standard: ","
        case .european: ";"
        }
    }

    var decimalSeparator: String {
        switch style {
        case .standard: "."
        case .european: ","
        }
    }
}
