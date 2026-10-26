//
//  TransactionExportImageTests.swift
//  TrenteTests
//
//  Created by Louis Carbo Estaque on 24/10/2026.
//

import Foundation
import Testing
@testable import Trente

struct TransactionExportImageTests {
    private let paris = TimeZone(identifier: "Europe/Paris")!
    private let jpeg = Data([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10])
    private let png = Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])

    private func isoMedia(brand: String) -> Data {
        Data([0x00, 0x00, 0x00, 0x18]) + Data("ftyp\(brand)".utf8) + Data([0x00, 0x00, 0x00, 0x00])
    }

    @Test(
        "Sanitizes titles for file names",
        arguments: [
            ("Groceries", "Groceries"),
            ("Rent: flat/2", "Rent- flat-2"),
            ("A\\B*C?D\"E<F>G|H", "A-B-C-D-E-F-G-H"),
            ("Line\nbreak", "Line-break"),
            ("  Lots   of \t space  ", "Lots of space"),
            ("", "Transaction"),
            ("   ", "Transaction"),
            ("Café ☕️", "Café ☕️")
        ]
    )
    func sanitizesTitle(title: String, expected: String) {
        #expect(TransactionExportImage.sanitizedTitle(title) == expected)
    }

    @Test("Caps the title part at 60 characters without a trailing space")
    func capsTitleLength() {
        let title = String(repeating: "a", count: 59) + " bcdef"

        #expect(TransactionExportImage.sanitizedTitle(title) == String(repeating: "a", count: 59))
        #expect(TransactionExportImage.sanitizedTitle(String(repeating: "b", count: 80)).count == 60)
    }

    @Test("Detects JPEG and PNG from their first bytes")
    func detectsJPEGAndPNG() {
        #expect(TransactionExportImage.fileExtension(for: jpeg) == "jpg")
        #expect(TransactionExportImage.fileExtension(for: png) == "png")
    }

    @Test("Detects HEIC from its file type brand", arguments: ["heic", "heix", "mif1", "hevc"])
    func detectsHEIC(brand: String) {
        #expect(TransactionExportImage.fileExtension(for: isoMedia(brand: brand)) == "heic")
    }

    @Test("Falls back to jpg for unknown or short data")
    func fallsBackToJPEG() {
        #expect(TransactionExportImage.fileExtension(for: Data()) == "jpg")
        #expect(TransactionExportImage.fileExtension(for: Data([0x89, 0x50])) == "jpg")
        #expect(TransactionExportImage.fileExtension(for: Data("GIF89a".utf8)) == "jpg")
        #expect(TransactionExportImage.fileExtension(for: isoMedia(brand: "mp42")) == "jpg")
    }

    @Test("Names an image after its day, title and transaction")
    func fileName() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = paris
        let date = calendar.date(from: DateComponents(year: 2026, month: 10, day: 5, hour: 23, minute: 30))!

        let fileName = TransactionExportImage.fileName(
            date: date,
            title: "Groceries / Market",
            transactionID: UUID(uuidString: "1A2B3C4D-0000-0000-0000-000000000001")!,
            data: png,
            timeZone: paris
        )

        #expect(fileName == "2026-10-05 Groceries - Market 1A2B3C4D.png")
        #expect(TransactionExportImage.relativePath(forFileName: fileName) == "Images/2026-10-05 Groceries - Market 1A2B3C4D.png")
    }
}
