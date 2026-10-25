//
//  NotificationSchedulerTests.swift
//  TrenteTests
//
//  Created by Louis Carbo Estaque on 25/10/2026.
//

import Testing
import Foundation
@testable import Trente

struct NotificationSchedulerTests {
    private let now = Date(timeIntervalSinceReferenceDate: 0)

    private func notification(_ identifier: String, title: String = "", inHours hours: Double) -> ScheduledNotification {
        ScheduledNotification(
            identifier: identifier,
            title: title,
            body: "",
            fireDate: now.addingTimeInterval(hours * 3600),
            threadIdentifier: "test"
        )
    }

    @Test("Only the soonest notifications are kept up to the limit")
    func keepsTheSoonestUpToTheLimit() {
        let notifications = [
            notification("later", inHours: 30),
            notification("soonest", inHours: 1),
            notification("dropped", inHours: 50),
            notification("soon", inHours: 5)
        ]

        let kept = NotificationScheduler.soonest(notifications, limit: 3)

        #expect(kept.map(\.identifier) == ["soonest", "soon", "later"])
    }

    @Test("Notifications firing together are ordered by title")
    func tiesAreOrderedByTitle() {
        let notifications = [
            notification("gym", title: "Gym", inHours: 1),
            notification("bakery", title: "Bakery", inHours: 1)
        ]

        let kept = NotificationScheduler.soonest(notifications, limit: 64)

        #expect(kept.map(\.identifier) == ["bakery", "gym"])
    }
}
