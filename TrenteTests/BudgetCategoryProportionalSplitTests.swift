//
//  BudgetCategoryProportionalSplitTests.swift
//  TrenteTests
//

import Testing
@testable import Trente

struct BudgetCategoryProportionalSplitTests {
    @Test("A split follows the weights and rounds needs and wants down to whole units")
    func followsWeights() {
        let split = BudgetCategory.proportionalSplit(
            of: 3000_00,
            weights: [.needs: 30, .wants: 40, .savingsAndDebts: 30]
        )

        #expect(split == [.needs: 900_00, .wants: 1200_00, .savingsAndDebts: 900_00])
    }

    @Test("Savings take what rounding leaves, so the split always adds up", arguments: [1000_01, 999_99, 2345_67, 1_00, 7_50])
    func alwaysAddsUp(amountCents: Int) {
        let split = BudgetCategory.proportionalSplit(
            of: amountCents,
            weights: [.needs: 1, .wants: 1, .savingsAndDebts: 1]
        )

        #expect(split.values.reduce(0, +) == amountCents)
        #expect(split[.needs]! % 100 == 0)
        #expect(split[.wants]! % 100 == 0)
    }

    @Test("Weights in cents and weights in percent give the same split")
    func weightsAreRelative() {
        let inPercent = BudgetCategory.proportionalSplit(of: 1234_00, weights: [.needs: 50, .wants: 30, .savingsAndDebts: 20])
        let inCents = BudgetCategory.proportionalSplit(of: 1234_00, weights: [.needs: 1000_00, .wants: 600_00, .savingsAndDebts: 400_00])

        #expect(inPercent == inCents)
    }

    @Test("A split with no weight is zero everywhere", arguments: [
        [:],
        [.needs: 0, .wants: 0, .savingsAndDebts: 0],
    ] as [[BudgetCategory: Int]])
    func zeroWithoutWeights(weights: [BudgetCategory: Int]) {
        let split = BudgetCategory.proportionalSplit(of: 1000_00, weights: weights)

        #expect(split == [.needs: 0, .wants: 0, .savingsAndDebts: 0])
    }

    @Test("No amount is a zero split")
    func zeroWithoutAmount() {
        let split = BudgetCategory.proportionalSplit(of: 0, weights: [.needs: 50, .wants: 30, .savingsAndDebts: 20])

        #expect(split == [.needs: 0, .wants: 0, .savingsAndDebts: 0])
    }

    @Test("Very large amounts keep the exact proportions")
    func largeAmountsStayExact() {
        let amountCents = 4_000_000_000_000
        let split = BudgetCategory.proportionalSplit(
            of: amountCents,
            weights: [.needs: 3_000_000_000_000, .wants: 2_000_000_000_000, .savingsAndDebts: 1_000_000_000_000]
        )

        #expect(split == [.needs: 2_000_000_000_000, .wants: 1_333_333_333_300, .savingsAndDebts: 666_666_666_700])
    }
}
