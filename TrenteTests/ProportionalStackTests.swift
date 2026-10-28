//
//  ProportionalStackTests.swift
//  TrenteTests
//
//  Created by Louis Carbo Estaque on 28/10/2026.
//

import Testing
import Foundation
@testable import Trente

struct ProportionalStackTests {
    @Test("Lengths follow the weights")
    func lengthsFollowWeights() {
        let lengths = ProportionalStack().lengths(for: [5, 3, 2], availableLength: 100)

        #expect(lengths == [50, 30, 20])
    }

    @Test("A tiny slice gets the minimum and the others share the rest by weight")
    func tinySliceGetsTheMinimum() {
        let stack = ProportionalStack(axis: .horizontal, spacing: 3, minimumLength: 3)

        let lengths = stack.lengths(for: [0.99, 0.01], availableLength: 100)

        #expect(lengths == [97, 3])
    }

    @Test("Without a minimum, a tiny slice keeps its weighted length")
    func noMinimumKeepsWeightedLength() {
        let lengths = ProportionalStack(axis: .horizontal).lengths(for: [0.99, 0.01], availableLength: 100)

        #expect(lengths == [99, 1])
    }
}
