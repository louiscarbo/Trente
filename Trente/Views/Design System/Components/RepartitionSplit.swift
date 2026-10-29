//
//  RepartitionSplit.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 28/10/2026.
//

import Foundation

struct RepartitionSplit: Equatable {
    static let adjustmentStepCount = 20

    var amountToSplit: Int
    var values: [BudgetCategory: Int]

    var remaining: Int {
        amountToSplit - values.values.reduce(0, +)
    }

    func amount(for category: BudgetCategory) -> Int {
        values[category] ?? 0
    }

    mutating func decrease(_ category: BudgetCategory) {
        values[category] = Self.decreasedValue(from: amount(for: category))
    }

    mutating func increase(_ category: BudgetCategory) {
        values[category] = Self.increasedValue(from: amount(for: category), remaining: remaining)
    }

    mutating func stepUp(_ category: BudgetCategory) {
        values[category] = Self.steppedUpValue(
            from: amount(for: category),
            total: amountToSplit,
            remaining: remaining
        )
    }

    mutating func stepDown(_ category: BudgetCategory) {
        values[category] = Self.steppedDownValue(from: amount(for: category), total: amountToSplit)
    }

    mutating func set(_ category: BudgetCategory, to proposedValue: Int) {
        values[category] = Self.clampedValue(proposedValue, from: amount(for: category), remaining: remaining)
    }

    func value(forDragFraction fraction: CGFloat, of category: BudgetCategory) -> Int {
        Self.dragValue(
            atFraction: fraction,
            total: amountToSplit,
            maxValue: amount(for: category) + remaining
        )
    }

    static func decreasedValue(from currentValue: Int) -> Int {
        let amountToDecrease = min(100, currentValue % 100 == 0 ? 100 : currentValue % 100)
        return max(0, currentValue - amountToDecrease)
    }

    static func increasedValue(from currentValue: Int, remaining: Int) -> Int {
        let amountToIncrease = min(100, remaining)
        return min(currentValue + amountToIncrease, currentValue + remaining)
    }

    static func clampedValue(_ proposedValue: Int, from currentValue: Int, remaining: Int) -> Int {
        let clampedNewValue = min(proposedValue, currentValue + remaining)
        let roundedValue = (clampedNewValue / 100) * 100
        return min(roundedValue, currentValue + remaining)
    }

    static func dragValue(atFraction fraction: CGFloat, total: Int, maxValue: Int) -> Int {
        let clampedFraction = min(max(0, fraction), 1)
        let rawNewValue = Int(round(clampedFraction * CGFloat(total)))
        let roundedNewValue = (rawNewValue / 100) * 100
        return min(roundedNewValue, maxValue)
    }

    static func steppedUpValue(from currentValue: Int, total: Int, remaining: Int) -> Int {
        let nextStepValue = adjustmentStepValues(total: total).first { $0 > currentValue } ?? currentValue
        return min(nextStepValue, currentValue + remaining)
    }

    static func steppedDownValue(from currentValue: Int, total: Int) -> Int {
        adjustmentStepValues(total: total).last { $0 < currentValue } ?? 0
    }

    private static func adjustmentStepValues(total: Int) -> [Int] {
        (0...adjustmentStepCount).map { step in
            guard step < adjustmentStepCount else { return total }
            let exactValue = total * step / adjustmentStepCount
            return min((exactValue + 50) / 100 * 100, total)
        }
    }
}
