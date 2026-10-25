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

    private var trigger: AppEventTrigger?

    private init() {}

    func start() {
        guard trigger == nil else { return }
        trigger = AppEventTrigger(events: [ModelContext.didSave], delay: .seconds(1)) {
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
}
