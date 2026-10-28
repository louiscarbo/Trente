//
//  RepartitionSplitTests.swift
//  TrenteTests
//
//  Created by Louis Carbo Estaque on 28/10/2026.
//

import Foundation
import Testing
@testable import Trente

struct RepartitionSplitTests {
    @Test("Decreasing removes the cents first, then whole units")
    func decreaseRemovesCentsFirst() {
        var split = RepartitionSplit(amountToSplit: 20_00, values: [.needs: 12_30])

        split.decrease(.needs)
        #expect(split.amount(for: .needs) == 12_00)

        split.decrease(.needs)
        #expect(split.amount(for: .needs) == 11_00)
    }

    @Test("Decreasing an empty category does nothing")
    func decreaseOnZeroDoesNothing() {
        var split = RepartitionSplit(amountToSplit: 20_00, values: [.needs: 0])

        split.decrease(.needs)

        #expect(split == RepartitionSplit(amountToSplit: 20_00, values: [.needs: 0]))
    }

    @Test("Decreasing an unset category stores zero")
    func decreaseOnUnsetCategoryStoresZero() {
        var split = RepartitionSplit(amountToSplit: 20_00, values: [:])

        split.decrease(.wants)

        #expect(split.values == [.wants: 0])
    }

    @Test("Decreasing cents only never goes below zero")
    func decreaseCentsOnlyStopsAtZero() {
        var split = RepartitionSplit(amountToSplit: 20_00, values: [.needs: 0_40])

        split.decrease(.needs)

        #expect(split.amount(for: .needs) == 0)
    }

    @Test("Increasing gives out the last cents")
    func increaseAddsLastCents() {
        var split = RepartitionSplit(amountToSplit: 60_30, values: [.needs: 60_00])

        split.increase(.needs)

        #expect(split.amount(for: .needs) == 60_30)
        #expect(split.remaining == 0)
    }

    @Test("Increasing adds one whole unit when enough is left")
    func increaseAddsOneUnit() {
        var split = RepartitionSplit(amountToSplit: 20_00, values: [.needs: 15_00])

        split.increase(.needs)

        #expect(split.amount(for: .needs) == 16_00)
    }

    @Test("Increasing with nothing left does nothing")
    func increaseWithNothingLeftDoesNothing() {
        var split = RepartitionSplit(amountToSplit: 20_00, values: [.needs: 15_00, .wants: 5_00])

        split.increase(.needs)

        #expect(split == RepartitionSplit(amountToSplit: 20_00, values: [.needs: 15_00, .wants: 5_00]))
    }

    @Test("Setting a value rounds it down to whole units")
    func setRoundsDown() {
        var split = RepartitionSplit(amountToSplit: 20_00, values: [:])

        split.set(.needs, to: 15_70)

        #expect(split.amount(for: .needs) == 15_00)
    }

    @Test("Setting beyond what is left is capped, then rounded down")
    func setBeyondRemainingIsCapped() {
        var split = RepartitionSplit(amountToSplit: 20_00, values: [.wants: 4_50])

        split.set(.needs, to: 30_00)

        #expect(split.amount(for: .needs) == 15_00)
        #expect(split.remaining == 0_50)
    }

    @Test("Setting a lower value drops the existing cents")
    func setLowerDropsCents() {
        var split = RepartitionSplit(amountToSplit: 20_00, values: [.needs: 12_30])

        split.set(.needs, to: 12_30)

        #expect(split.amount(for: .needs) == 12_00)
    }

    @Test("Dragging to the end stops before the last cents")
    func dragToEndKeepsCents() {
        let split = RepartitionSplit(amountToSplit: 60_30, values: [:])

        #expect(split.value(forDragFraction: 1, of: .needs) == 60_00)
    }

    @Test("Dragging rounds to the nearest cent, then down to whole units")
    func dragRoundsDown() {
        let split = RepartitionSplit(amountToSplit: 60_30, values: [:])

        #expect(split.value(forDragFraction: 0.5, of: .needs) == 30_00)
        #expect(split.value(forDragFraction: 0.99, of: .needs) == 59_00)
    }

    @Test("Dragging outside the slider is clamped to its ends")
    func dragOutsideIsClamped() {
        let split = RepartitionSplit(amountToSplit: 60_30, values: [:])

        #expect(split.value(forDragFraction: -0.2, of: .needs) == 0)
        #expect(split.value(forDragFraction: 1.5, of: .needs) == 60_00)
    }

    @Test("Dragging is capped at what the category can take, cents included")
    func dragIsCappedAtMaxValue() {
        var split = RepartitionSplit(amountToSplit: 60_30, values: [.wants: 40_00])

        let draggedValue = split.value(forDragFraction: 1, of: .needs)
        #expect(draggedValue == 20_30)

        split.set(.needs, to: draggedValue)
        #expect(split.amount(for: .needs) == 20_00)
    }

    @Test("Remaining always equals the amount to split minus every value")
    func remainingMatchesValues() {
        var split = RepartitionSplit(amountToSplit: 60_30, values: [:])
        let steps: [(inout RepartitionSplit) -> Void] = [
            { $0.set(.needs, to: $0.value(forDragFraction: 0.5, of: .needs)) },
            { $0.increase(.wants) },
            { $0.set(.savingsAndDebts, to: 100_00) },
            { $0.increase(.needs) },
            { $0.decrease(.needs) },
            { $0.decrease(.needs) },
            { $0.decrease(.wants) },
            { $0.increase(.savingsAndDebts) }
        ]

        for step in steps {
            step(&split)
            #expect(split.remaining == split.amountToSplit - split.values.values.reduce(0, +))
            #expect(split.remaining >= 0)
        }
        #expect(split.values == [.needs: 29_00, .wants: 0, .savingsAndDebts: 30_00])
    }
}
