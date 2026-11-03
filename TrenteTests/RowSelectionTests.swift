//
//  RowSelectionTests.swift
//  TrenteTests
//
//  Created by Louis Carbo Estaque on 30/10/2026.
//

import Testing
@testable import Trente

struct RowSelectionTests {
    private struct Row: Identifiable, Equatable {
        let id: Int
    }

    @Test("Rows filtered out or gone don't count and aren't returned")
    func hiddenRowsAreLeftOut() {
        var selection = RowSelection<Int>()
        selection.selectedIDs = [1, 2, 3]
        let visibleRows = [Row(id: 2), Row(id: 3), Row(id: 4)]

        #expect(selection.selectedCount(in: visibleRows.map(\.id)) == 2)
        #expect(selection.selected(in: visibleRows) == [Row(id: 2), Row(id: 3)])
    }
}
