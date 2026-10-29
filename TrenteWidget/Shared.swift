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
    makeEntry: (Date, WidgetMonth?) -> Entry
) -> Timeline<Entry> {
    do {
        let entries = try currentMonthSnapshots(from: now).map { makeEntry($0.date, $0.month) }
        return Timeline(entries: entries, policy: .atEnd)
    } catch {
        logger.error("Could not load the current month: \(error, privacy: .public)")
        return Timeline(
            entries: [makeEntry(now, nil)],
            policy: .after(now.addingTimeInterval(retryDelay))
        )
    }
}

private func currentMonthSnapshots(from now: Date) throws -> [(date: Date, month: WidgetMonth?)] {
    let configuration = ModelConfiguration(schema: .trente, cloudKitDatabase: .none)
    let context = ModelContext(try ModelContainer(for: .trente, migrationPlan: TrenteMigrationPlan.self, configurations: [configuration]))
    var descriptor = FetchDescriptor<Month>(sortBy: [SortDescriptor(\Month.startDate, order: .reverse)])
    descriptor.fetchLimit = 1
    guard let month = try context.fetch(descriptor).first else {
        return Calendar.current.timelineDates(from: now, dueDates: []).map { ($0, nil) }
    }

    let automaticRules = TrentePlusEntitlement.cached()
        ? try context.fetch(FetchDescriptor<RecurringTransactionRule>(predicate: #Predicate { $0.autoConfirm == true }))
        : []
    let dueDates = automaticRules
        .flatMap { $0.dueAutomaticOccurrences(in: month, by: month.dateInterval.end) }
        .map(\.date)
    return Calendar.current.timelineDates(from: now, dueDates: dueDates).map { date in
        let dueOccurrences = automaticRules.flatMap { $0.dueAutomaticOccurrences(in: month, by: date) }
        return (date, WidgetMonth(month: month, automaticOccurrences: dueOccurrences))
    }
}
