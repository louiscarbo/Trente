//
//  AppEventTrigger.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 25/10/2026.
//

import Foundation
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

@MainActor
final class AppEventTrigger {
    private let delay: Duration
    private let action: @MainActor () async -> Void
    private var observers: [any NSObjectProtocol] = []
    private var task: Task<Void, Never>?

    init(
        events: [Notification.Name],
        delay: Duration = .zero,
        action: @escaping @MainActor () async -> Void
    ) {
        self.delay = delay
        self.action = action
        observers = events.map { event in
            NotificationCenter.default.addObserver(forName: event, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated {
                    self?.fire()
                }
            }
        }
    }

    func fire() {
        let previousTask = task
        previousTask?.cancel()
        task = Task { [delay, action] in
            try? await Task.sleep(for: delay)
            await previousTask?.value
            guard !Task.isCancelled else { return }
            await action()
        }
    }
}

extension Notification.Name {
    static var appDidBecomeActive: Notification.Name {
        #if os(iOS)
        UIApplication.didBecomeActiveNotification
        #elseif os(macOS)
        NSApplication.didBecomeActiveNotification
        #endif
    }
}
