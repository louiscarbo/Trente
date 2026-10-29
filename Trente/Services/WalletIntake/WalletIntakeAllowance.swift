//
//  WalletIntakeAllowance.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 29/10/2026.
//

import Foundation

struct WalletIntakeAllowance {
    static let freeMonthlyLimit = 10
    static let monthKey = "walletIntake.month"
    static let countKey = "walletIntake.count"

    var defaults: UserDefaults = TrentePlusEntitlement.sharedDefaults
    var calendar: Calendar = .current

    func count(on date: Date) -> Int {
        guard defaults.string(forKey: Self.monthKey) == monthIdentifier(of: date) else { return 0 }
        return defaults.integer(forKey: Self.countKey)
    }

    func allowsIntake(on date: Date, isTrentePlusSubscribed: Bool) -> Bool {
        isTrentePlusSubscribed || count(on: date) < Self.freeMonthlyLimit
    }

    func recordIntake(on date: Date) {
        setCount(count(on: date) + 1, on: date)
    }

    func cancelIntake(on date: Date) {
        setCount(max(count(on: date) - 1, 0), on: date)
    }

    func setCount(_ count: Int, on date: Date) {
        defaults.set(monthIdentifier(of: date), forKey: Self.monthKey)
        defaults.set(count, forKey: Self.countKey)
    }

    private func monthIdentifier(of date: Date) -> String {
        let components = calendar.dateComponents([.year, .month], from: date)
        return "\(components.year ?? 0)-\(components.month ?? 0)"
    }
}
