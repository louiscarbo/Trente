//
//  ExportSelectionTests.swift
//  TrenteTests
//
//  Created by Louis Carbo Estaque on 27/10/2026.
//

import Foundation
import Testing
@testable import Trente

struct ExportSelectionTests {
    private let october = ExportMonthOption(id: UUID(), name: "October", startDate: .now, transactionCount: 4)
    private let september = ExportMonthOption(id: UUID(), name: "September", startDate: .now, transactionCount: 7)

    private func selection(
        excluding excludedMonthIDs: Set<UUID> = [],
        imagesIn monthIDsWithImages: Set<UUID> = []
    ) -> ExportSelection {
        ExportSelection(
            options: [october, september],
            excludedMonthIDs: excludedMonthIDs,
            monthIDsWithImages: monthIDsWithImages,
            format: TransactionCSVFormat()
        )
    }

    @Test("Every month is selected until one is excluded")
    func everyMonthSelectedByDefault() {
        let selection = selection()

        #expect(selection.includesEveryMonth)
        #expect(selection.transactionCount == 11)
        #expect(selection.file.monthIDs == [october.id, september.id])
    }

    @Test("Excluded months leave the count and the file")
    func excludedMonthsAreLeftOut() {
        let selection = selection(excluding: [september.id])

        #expect(!selection.includesEveryMonth)
        #expect(selection.selectedOptions == [october])
        #expect(selection.transactionCount == 4)
        #expect(selection.file.monthIDs == [october.id])
    }

    @Test("The file has images only when a selected month has some")
    func imagesFollowTheSelectedMonths() {
        #expect(selection(imagesIn: [september.id]).file.hasImages)
        #expect(!selection(excluding: [september.id], imagesIn: [september.id]).file.hasImages)
    }
}
