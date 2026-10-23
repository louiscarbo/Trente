//
//  WidgetRefresher.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 23/10/2026.
//

import Foundation
import SwiftData
import WidgetKit

@MainActor
final class WidgetRefresher {
    static let shared = WidgetRefresher()

    private let debounceDelay: Duration = .seconds(1)
    private var saveObserver: (any NSObjectProtocol)?
    private var reloadTask: Task<Void, Never>?

    private init() {}

    func start() {
        guard saveObserver == nil else { return }
        saveObserver = NotificationCenter.default.addObserver(
            forName: ModelContext.didSave,
            object: nil,
            queue: .main
        ) { _ in
            MainActor.assumeIsolated {
                WidgetRefresher.shared.scheduleReload()
            }
        }
    }

    private func scheduleReload() {
        reloadTask?.cancel()
        reloadTask = Task { [debounceDelay] in
            try? await Task.sleep(for: debounceDelay)
            guard !Task.isCancelled else { return }
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
}
