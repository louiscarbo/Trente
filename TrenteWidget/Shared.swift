//
//  Shared.swift
//  TrenteWidgetExtension
//
//  Created by Louis Carbo Estaque on 24/04/2025.
//

import Foundation
import OSLog
import SwiftData
import WidgetKit

private let logger = Logger(subsystem: "louiscarboestaque.Trente.TrenteWidget", category: "Timeline")
private let retryDelay: TimeInterval = 15 * 60

func currentMonthTimeline<Entry: TimelineEntry>(
    from now: Date = .now,
    policy: TimelineReloadPolicy,
    makeEntry: (Date, WidgetMonth?) -> Entry
) -> Timeline<Entry> {
    do {
        let entries = try currentMonthSnapshots(from: now).map { makeEntry($0.date, $0.month) }
        return Timeline(entries: entries, policy: policy)
    } catch {
        logger.error("Could not load the current month: \(error, privacy: .public)")
        return Timeline(
            entries: [makeEntry(now, nil)],
            policy: .after(now.addingTimeInterval(retryDelay))
        )
    }
}

private func currentMonthSnapshots(from now: Date) throws -> [(date: Date, month: WidgetMonth?)] {
    let context = ModelContext(try ModelContainer(for: .trente, migrationPlan: TrenteMigrationPlan.self))
    var descriptor = FetchDescriptor<Month>(sortBy: [SortDescriptor(\Month.startDate, order: .reverse)])
    descriptor.fetchLimit = 1
    guard let month = try context.fetch(descriptor).first else { return [(now, nil)] }

    let automaticRules = try context.fetch(
        FetchDescriptor<RecurringTransactionRule>(predicate: #Predicate { $0.autoConfirm == true })
    )
    let upcomingDueDates = Set(
        automaticRules
            .flatMap { $0.dueAutomaticOccurrences(in: month, by: month.dateInterval.end) }
            .map(\.date)
            .filter { $0 > now }
    )
    return ([now] + upcomingDueDates.sorted()).map { date in
        let dueOccurrences = automaticRules.flatMap { $0.dueAutomaticOccurrences(in: month, by: date) }
        return (date, WidgetMonth(month: month, automaticOccurrences: dueOccurrences))
    }
}
