//
//  Shared.swift
//  TrenteWidgetExtension
//
//  Created by Louis Carbo Estaque on 24/04/2025.
//

import Foundation
import SwiftData

func getCurrentMonth() throws -> WidgetMonth? {
    let modelContainer = try ModelContainer(for: .trente, migrationPlan: TrenteMigrationPlan.self)
    var descriptor = FetchDescriptor<Month>(sortBy: [SortDescriptor(\Month.startDate, order: .reverse)])
    descriptor.fetchLimit = 1
    return try ModelContext(modelContainer).fetch(descriptor).first.map(WidgetMonth.init(month:))
}
