//
//  BudgetFiguresGaugeTests.swift
//  TrenteTests
//

import Testing
@testable import Trente

struct BudgetFiguresGaugeTests {
    private func figures(spent: Double, income: Double) -> BudgetFigures {
        BudgetFigures(spent: spent, income: income, remaining: income - spent)
    }

    private func isClose(_ value: Double, to expected: Double) -> Bool {
        abs(value - expected) < 1e-9
    }

    @Test("With nothing spent the indicator sits at the right end and the whole arc is highlighted on Left")
    func fullAtTheStart() {
        let start = figures(spent: 0, income: 300)

        #expect(start.gaugeIndicator(in: .all) == 1)
        #expect(start.gaugeHighlight(showingRemaining: true, in: .all) == 0...1)
    }

    @Test("The indicator follows what is left and moves toward the left start as money is spent", arguments: [
        (0.0, 1.0), (75.0, 0.75), (150.0, 0.5), (225.0, 0.25), (300.0, 0.0)
    ])
    func indicatorIsTheLeftFraction(spent: Double, expected: Double) {
        let indicator = figures(spent: spent, income: 300).gaugeIndicator(in: .category(.needs))

        #expect(isClose(indicator, to: expected))
    }

    @Test("On Left the highlight runs from the left start to the indicator")
    func leftHighlightEndsAtTheIndicator() {
        let midway = figures(spent: 100, income: 300)
        let highlight = midway.gaugeHighlight(showingRemaining: true, in: .all)

        #expect(highlight.lowerBound == 0)
        #expect(isClose(highlight.upperBound, to: midway.gaugeIndicator(in: .all)))
    }

    @Test("On Spent the highlight runs from the indicator to the right end")
    func spentHighlightStartsAtTheIndicator() {
        let midway = figures(spent: 100, income: 300)
        let highlight = midway.gaugeHighlight(showingRemaining: false, in: .all)

        #expect(isClose(highlight.lowerBound, to: midway.gaugeIndicator(in: .all)))
        #expect(highlight.upperBound == 1)
    }

    @Test("A tap moves the highlight and not the indicator", arguments: [0.0, 40.0, 150.0, 300.0, 450.0])
    func tapKeepsTheIndicator(spent: Double) {
        let state = figures(spent: spent, income: 300)
        let onLeft = state.gaugeHighlight(showingRemaining: true, in: .category(.wants))
        let onSpent = state.gaugeHighlight(showingRemaining: false, in: .category(.wants))
        let indicator = state.gaugeIndicator(in: .category(.wants))

        #expect(isClose(onLeft.upperBound, to: indicator))
        #expect(isClose(onSpent.lowerBound, to: indicator))
    }

    @Test("With everything spent the indicator reaches the left start and Left highlights nothing")
    func emptyWhenEverythingIsSpent() {
        let empty = figures(spent: 300, income: 300)

        #expect(empty.gaugeIndicator(in: .all) == 0)
        #expect(empty.gaugeHighlight(showingRemaining: true, in: .all) == 0...0)
        #expect(empty.gaugeHighlight(showingRemaining: false, in: .all) == 0...1)
    }

    @Test("Over budget the indicator stays at the left start and Spent highlights the whole arc")
    func overBudgetStopsAtZero() {
        let over = figures(spent: 450, income: 300)

        #expect(over.gaugeIndicator(in: .category(.needs)) == 0)
        #expect(over.gaugeHighlight(showingRemaining: true, in: .category(.needs)) == 0...0)
        #expect(over.gaugeHighlight(showingRemaining: false, in: .category(.needs)) == 0...1)
    }

    @Test("Saving more than planned fills the arc whichever side is shown", arguments: [true, false])
    func extraSavedFillsTheArc(showingRemaining: Bool) {
        let extra = figures(spent: 450, income: 300)
        let savings = BudgetScope.category(.savingsAndDebts)

        #expect(extra.gaugeIndicator(in: savings) == 1)
        #expect(extra.gaugeHighlight(showingRemaining: showingRemaining, in: savings) == 0...1)
    }

    @Test("Spent shows nothing highlighted while nothing is spent")
    func spentIsEmptyWithNothingSpent() {
        let start = figures(spent: 0, income: 300)
        let highlight = start.gaugeHighlight(showingRemaining: false, in: .all)

        #expect(highlight.lowerBound == highlight.upperBound)
    }

    @Test("Without income the indicator rests at the left start and Spent highlights nothing")
    func noIncomeRestsAtZero() {
        let noIncome = figures(spent: 0, income: 0)
        let highlight = noIncome.gaugeHighlight(showingRemaining: false, in: .all)

        #expect(noIncome.gaugeIndicator(in: .all) == 0)
        #expect(highlight.lowerBound == highlight.upperBound)
    }
}
