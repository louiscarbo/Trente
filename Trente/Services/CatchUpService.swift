//
//  CatchUpService.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 24/10/2026.
//

import Foundation
import SwiftData
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

@MainActor
final class CatchUpService {
    static let shared = CatchUpService()

    private var container: ModelContainer?
    private var observers: [any NSObjectProtocol] = []
    private var catchUpTask: Task<Void, Never>?

    private init() {}

    func start(container: ModelContainer) {
        guard observers.isEmpty else { return }
        self.container = container
        let triggers = [Self.didBecomeActive, .NSCalendarDayChanged, ModelContext.didSave]
        observers = triggers.map { trigger in
            NotificationCenter.default.addObserver(forName: trigger, object: nil, queue: .main) { _ in
                MainActor.assumeIsolated {
                    CatchUpService.shared.scheduleCatchUp()
                }
            }
        }
    }

    func catchUp(in context: ModelContext, now: Date = .now) throws {
        try MonthService.shared.createMissingMonths(in: context, now: now)
        try RecurringTransactionService.shared.confirmDueOccurrences(in: context, now: now)
    }

    private func scheduleCatchUp() {
        catchUpTask?.cancel()
        catchUpTask = Task {
            guard !Task.isCancelled, let container else { return }
            try? catchUp(in: container.mainContext)
        }
    }

    private static var didBecomeActive: Notification.Name {
        #if os(iOS)
        UIApplication.didBecomeActiveNotification
        #elseif os(macOS)
        NSApplication.didBecomeActiveNotification
        #endif
    }
}
