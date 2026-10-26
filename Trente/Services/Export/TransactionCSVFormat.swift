//
//  TransactionCSVFormat.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 24/10/2026.
//

import Foundation

struct TransactionCSVFormat: Hashable, Sendable {
    enum Style: Sendable {
        case standard
        case european

        static var current: Style {
            Style(locale: .current)
        }

        init(locale: Locale) {
            self = locale.decimalSeparator == "," ? .european : .standard
        }
    }

    static let includesNotesKey = "export.includesNotes"
    static let includesImagesKey = "export.includesImages"

    var style: Style = .standard
    var includesNotes = true
    var includesImages = true

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
