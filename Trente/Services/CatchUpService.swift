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
    private var syncTrigger: AppEventTrigger?

    private init() {}

    func start(container: ModelContainer) {
        guard trigger == nil else { return }
        trigger = AppEventTrigger(events: [.appDidBecomeActive, .NSCalendarDayChanged, ModelContext.didSave]) {
            try? CatchUpService.shared.catchUp(in: container.mainContext)
        }
        syncTrigger = AppEventTrigger(events: [.NSPersistentStoreRemoteChange], delay: .seconds(2)) {
            try? CatchUpService.shared.catchUpAfterSync(in: container.mainContext)
        }
        syncTrigger?.fire()
    }

    func catchUpAfterSync(in context: ModelContext, now: Date = .now) throws {
        try SyncDuplicateCleaner.mergeDuplicates(in: context)
        try catchUp(in: context, now: now)
    }

    func catchUp(in context: ModelContext, now: Date = .now) throws {
        try MonthService.shared.createMissingMonths(in: context, now: now)
        try RecurringTransactionService.shared.confirmDueOccurrences(in: context, now: now)
    }
}
