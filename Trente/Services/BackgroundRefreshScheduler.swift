//
//  BackgroundRefreshScheduler.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 20/05/2026.
//

#if os(iOS)
import BackgroundTasks
import SwiftData
import WidgetKit

enum BackgroundRefreshScheduler {
    static let taskIdentifier = "com.louiscarboestaque.Trente.autoConfirmRecurring"

    /// Must be called synchronously at app launch, before the scene is shown.
    static func registerHandler() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: taskIdentifier, using: nil) { task in
            guard let refreshTask = task as? BGAppRefreshTask else {
                task.setTaskCompleted(success: false)
                return
            }
            handle(task: refreshTask)
        }
    }

    /// Schedules the next background refresh request.
    static func schedule(after interval: TimeInterval = 6 * 3600) {
        let request = BGAppRefreshTaskRequest(identifier: taskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: interval)
        try? BGTaskScheduler.shared.submit(request)
    }

    private static func handle(task: BGAppRefreshTask) {
        // Re-schedule first so a crash in the handler doesn't break the cycle.
        schedule()

        let workTask = Task {
            do {
                let container = try AppGroup.makeContainer()
                let context = ModelContext(container)
                let count = try RecurringTransactionService.shared.autoConfirmDueInstances(asOf: .now, in: context)
                if count > 0 {
                    WidgetCenter.shared.reloadAllTimelines()
                }
                task.setTaskCompleted(success: true)
            } catch {
                task.setTaskCompleted(success: false)
            }
        }

        task.expirationHandler = {
            workTask.cancel()
        }
    }
}
#endif
