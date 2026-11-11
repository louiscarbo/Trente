//
//  FoldColumnsTests.swift
//  TrenteTests
//
//  Created by Louis Carbo Estaque on 31/10/2026.
//

import CoreGraphics
import Testing
@testable import Trente

struct FoldColumnsTests {
    private let duoFold = CGRect(x: 456, y: 0, width: 40, height: 669)
    private let duoUsableWidth: CGFloat = 867

    @Test("The iPhone Duo fold gives a 436 pt left column and a 355 pt right column")
    func iPhoneDuoLandscape() {
        let columns = MonthView.FoldColumns.around(fold: duoFold, containerWidth: duoUsableWidth)

        #expect(columns == MonthView.FoldColumns(leadingWidth: 436, trailingWidth: 355, spacing: 40))
    }

    @Test("Margins, columns and the fold add up to the whole width")
    func columnsFillTheWidth() throws {
        let columns = try #require(MonthView.FoldColumns.around(fold: duoFold, containerWidth: duoUsableWidth))

        let total = MonthView.FoldColumns.leadingMargin
            + columns.leadingWidth
            + columns.spacing
            + columns.trailingWidth
            + MonthView.FoldColumns.trailingMargin

        #expect(total == duoUsableWidth)
    }

    @Test("The left column ends where the fold starts, and the right one starts where it ends")
    func columnsStopAtTheFold() throws {
        let columns = try #require(MonthView.FoldColumns.around(fold: duoFold, containerWidth: duoUsableWidth))

        #expect(MonthView.FoldColumns.leadingMargin + columns.leadingWidth == duoFold.minX)
        #expect(duoUsableWidth - MonthView.FoldColumns.trailingMargin - columns.trailingWidth == duoFold.maxX)
    }

    @Test("Add Transaction's slot lines the button up with the right column")
    func addButtonSlot() throws {
        let columns = try #require(MonthView.FoldColumns.around(fold: duoFold, containerWidth: duoUsableWidth))

        #expect(columns.addButtonSlotWidth == 387)
    }

    @Test("A horizontal fold, as in portrait, leaves the layout alone")
    func horizontalFold() {
        let fold = CGRect(x: 0, y: 456, width: 669, height: 40)

        #expect(MonthView.FoldColumns.around(fold: fold, containerWidth: 669) == nil)
    }

    @Test("A fold too close to either side leaves the layout alone")
    func foldNearAnEdge() {
        let nearLeading = CGRect(x: 200, y: 0, width: 40, height: 669)
        let nearTrailing = CGRect(x: 700, y: 0, width: 40, height: 669)

        #expect(MonthView.FoldColumns.around(fold: nearLeading, containerWidth: duoUsableWidth) == nil)
        #expect(MonthView.FoldColumns.around(fold: nearTrailing, containerWidth: duoUsableWidth) == nil)
    }

    @Test("A fold outside the view leaves the layout alone")
    func foldOutsideTheView() {
        let fold = CGRect(x: 900, y: 0, width: 40, height: 669)

        #expect(MonthView.FoldColumns.around(fold: fold, containerWidth: duoUsableWidth) == nil)
    }

    @Test("Columns exactly at the minimum width still step over the fold")
    func columnsAtTheMinimum() {
        let minimum = MonthView.FoldColumns.minimumWidth
        let fold = CGRect(x: MonthView.FoldColumns.leadingMargin + minimum, y: 0, width: 40, height: 669)

        let columns = MonthView.FoldColumns.around(fold: fold, containerWidth: fold.maxX + minimum + MonthView.FoldColumns.trailingMargin)

        #expect(columns == MonthView.FoldColumns(leadingWidth: minimum, trailingWidth: minimum, spacing: 40))
    }
}
