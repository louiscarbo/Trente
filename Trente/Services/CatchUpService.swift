//
//  CatchUpService.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 24/10/2026.
//

import Foundation
import SwiftData
import CoreData

@MainActor
final class CatchUpService {
    static let shared = CatchUpService()

    private var trigger: AppEventTrigger?

    private init() {}

    func start(container: ModelContainer) {
        guard trigger == nil else { return }
        let events: [Notification.Name] = [.appDidBecomeActive, .NSCalendarDayChanged, ModelContext.didSave, .NSPersistentStoreRemoteChange]
        trigger = AppEventTrigger(events: events) {
            try? CatchUpService.shared.catchUp(in: container.mainContext)
        }
    }

    func catchUp(in context: ModelContext, now: Date = .now) throws {
        try SyncDuplicateCleaner.mergeDuplicates(in: context)
        try MonthService.shared.createMissingMonths(in: context, now: now)
        try RecurringTransactionService.shared.confirmDueOccurrences(in: context, now: now)
    }
}
