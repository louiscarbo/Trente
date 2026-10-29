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
        let events = [
            ModelContext.didSave,
            .appDidBecomeActive,
            .NSCalendarDayChanged,
            TrentePlusEntitlement.didChange
        ]
        trigger = AppEventTrigger(events: events) {
            let isSubscribed = await TrentePlusStatus.shared.currentStatus()
            try? CatchUpService.shared.catchUp(in: container.mainContext, isTrentePlusSubscribed: isSubscribed)
        }
        syncTrigger = AppEventTrigger(events: [.NSPersistentStoreRemoteChange], delay: .seconds(2)) {
            let isSubscribed = await TrentePlusStatus.shared.currentStatus()
            try? CatchUpService.shared.catchUpAfterSync(in: container.mainContext, isTrentePlusSubscribed: isSubscribed)
        }
        syncTrigger?.fire()
    }

    func catchUpAfterSync(
        in context: ModelContext,
        now: Date = .now,
        isTrentePlusSubscribed: Bool = TrentePlusEntitlement.cached()
    ) throws {
        try SyncDuplicateCleaner.mergeDuplicates(in: context)
        try catchUp(in: context, now: now, isTrentePlusSubscribed: isTrentePlusSubscribed)
    }

    func catchUp(
        in context: ModelContext,
        now: Date = .now,
        isTrentePlusSubscribed: Bool = TrentePlusEntitlement.cached()
    ) throws {
        try MonthService.shared.createMissingMonths(in: context, now: now)
        try RecurringTransactionService.shared.confirmDueOccurrences(
            in: context,
            now: now,
            isAutomaticUnlocked: isTrentePlusSubscribed
        )
    }
}
