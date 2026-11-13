//
//  BudgetFiguresGaugeTests.swift
//  TrenteTests
//

import Testing
@testable import Trente

struct BudgetFiguresGaugeTests {
    private let onLeft = GaugeHighlight(left: true, spent: false)
    private let onSpent = GaugeHighlight(left: false, spent: true)
    private let nothing = GaugeHighlight(left: false, spent: false)

    private func figures(spent: Double, income: Double) -> BudgetFigures {
        BudgetFigures(spent: spent, income: income, remaining: income - spent)
    }

    private func isClose(_ value: Double, to expected: Double) -> Bool {
        abs(value - expected) < 1e-9
    }

    @Test("With nothing spent the indicator sits at the right end and the left part is the whole arc")
    func fullAtTheStart() {
        let start = figures(spent: 0, income: 300)

        #expect(start.gaugeIndicator(in: .all) == 1)
        #expect(start.gaugeHighlight(showingRemaining: true, in: .all) == onLeft)
    }

    @Test("The indicator follows what is left and moves toward the left start as money is spent", arguments: [
        (0.0, 1.0), (75.0, 0.75), (150.0, 0.5), (225.0, 0.25), (300.0, 0.0)
    ])
    func indicatorIsTheLeftFraction(spent: Double, expected: Double) {
        let indicator = figures(spent: spent, income: 300).gaugeIndicator(in: .category(.needs))

        #expect(isClose(indicator, to: expected))
    }

    @Test("On Left only the left part is vivid")
    func leftShowsTheLeftPart() {
        let midway = figures(spent: 100, income: 300)

        #expect(midway.gaugeHighlight(showingRemaining: true, in: .all) == onLeft)
    }

    @Test("On Spent only the spent part is vivid")
    func spentShowsTheSpentPart() {
        let midway = figures(spent: 100, income: 300)

        #expect(midway.gaugeHighlight(showingRemaining: false, in: .all) == onSpent)
    }

    @Test("A tap swaps which part is vivid and leaves the indicator where it is", arguments: [0.0, 40.0, 150.0, 300.0, 450.0])
    func tapKeepsTheIndicator(spent: Double) {
        let state = figures(spent: spent, income: 300)
        let scope = BudgetScope.category(.wants)
        let indicatorBefore = state.gaugeIndicator(in: scope)

        let left = state.gaugeHighlight(showingRemaining: true, in: scope)
        let right = state.gaugeHighlight(showingRemaining: false, in: scope)

        #expect(left.left && !left.spent)
        #expect(!right.left)
        #expect(isClose(state.gaugeIndicator(in: scope), to: indicatorBefore))
    }

    @Test("With everything spent the indicator reaches the left start and the whole arc is the spent part")
    func emptyWhenEverythingIsSpent() {
        let empty = figures(spent: 300, income: 300)

        #expect(empty.gaugeIndicator(in: .all) == 0)
        #expect(empty.gaugeHighlight(showingRemaining: true, in: .all) == onLeft)
        #expect(empty.gaugeHighlight(showingRemaining: false, in: .all) == onSpent)
    }

    @Test("Over budget the indicator stays at the left start")
    func overBudgetStopsAtZero() {
        let over = figures(spent: 450, income: 300)

        #expect(over.gaugeIndicator(in: .category(.needs)) == 0)
        #expect(over.gaugeHighlight(showingRemaining: false, in: .category(.needs)) == onSpent)
    }

    @Test("Saving more than planned fills the arc whichever side is shown", arguments: [true, false])
    func extraSavedFillsTheArc(showingRemaining: Bool) {
        let extra = figures(spent: 450, income: 300)
        let savings = BudgetScope.category(.savingsAndDebts)

        #expect(extra.gaugeIndicator(in: savings) == 1)
        #expect(extra.gaugeHighlight(showingRemaining: showingRemaining, in: savings) == onLeft)
    }

    @Test("Spent highlights nothing while nothing is spent")
    func spentIsEmptyWithNothingSpent() {
        let start = figures(spent: 0, income: 300)

        #expect(start.gaugeHighlight(showingRemaining: false, in: .all) == nothing)
    }

    @Test("Without income the indicator rests at the left start and Spent highlights nothing")
    func noIncomeRestsAtZero() {
        let noIncome = figures(spent: 0, income: 0)

        #expect(noIncome.gaugeIndicator(in: .all) == 0)
        #expect(noIncome.gaugeHighlight(showingRemaining: false, in: .all) == nothing)
    }
}
