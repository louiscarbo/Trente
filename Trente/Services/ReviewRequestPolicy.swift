//
//  ReviewRequestPolicy.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 24/10/2026.
//

import Foundation

enum ReviewRequestPolicy {
    enum Keys {
        static let lastRequestedVersion = "reviewRequest.lastVersion"
        static let lastRequestedMonthCount = "reviewRequest.lastMonthCount"
        static let firstUseTimestamp = "reviewRequest.firstUseTimestamp"
    }

    static let minimumMonthCount = 2
    static let minimumDaysOfUse = 14
    static let delay: Duration = .seconds(3)

    static func shouldRequest(
        monthCount: Int,
        lastRequestedMonthCount: Int,
        lastRequestedVersion: String,
        currentVersion: String,
        firstUseDate: Date?,
        now: Date,
        calendar: Calendar = .current
    ) -> Bool {
        guard monthCount >= minimumMonthCount,
              monthCount > lastRequestedMonthCount,
              currentVersion != lastRequestedVersion,
              let firstUseDate,
              let daysOfUse = calendar.dateComponents(
                  [.day],
                  from: calendar.startOfDay(for: firstUseDate),
                  to: calendar.startOfDay(for: now)
              ).day
        else { return false }
        return daysOfUse >= minimumDaysOfUse
    }

    static func reset(in defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: Keys.lastRequestedVersion)
        defaults.removeObject(forKey: Keys.lastRequestedMonthCount)
        defaults.removeObject(forKey: Keys.firstUseTimestamp)
    }
}
