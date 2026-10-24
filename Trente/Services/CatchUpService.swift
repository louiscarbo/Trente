//
//  CatchUpService.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 24/10/2026.
//

import Foundation
import SwiftData

@MainActor
final class CatchUpService {
    static let shared = CatchUpService()

    private var trigger: AppEventTrigger?

    private init() {}

    func start(container: ModelContainer) {
        guard trigger == nil else { return }
        trigger = AppEventTrigger(events: [.appDidBecomeActive, .NSCalendarDayChanged, ModelContext.didSave]) {
            try? CatchUpService.shared.catchUp(in: container.mainContext)
        }
    }

    func catchUp(in context: ModelContext, now: Date = .now) throws {
        try MonthService.shared.createMissingMonths(in: context, now: now)
        try RecurringTransactionService.shared.confirmDueOccurrences(in: context, now: now)
    }
}
