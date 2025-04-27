//
//  Shared.swift
//  TrenteWidgetExtension
//
//  Created by Louis Carbo Estaque on 24/04/2025.
//

import Foundation
import SwiftData

@MainActor
func getCurrentMonth(inPreview: Bool = false) -> Month? {
    if inPreview {
        do {
            let modelContainer = DataProvider.shared.modelContainer
            let descriptor = FetchDescriptor<Month>(sortBy: [SortDescriptor(\Month.startDate, order: .forward)])
            let month = try modelContainer.mainContext.fetch(descriptor)[3]
            return month.detachedCopy()
        } catch {
            print("Error fetching SAMPLE month budget: \(error)")
        }
    }
    
    do {
        let modelContainer = try ModelContainer(for: Month.self)
        let descriptor = FetchDescriptor<Month>(sortBy: [SortDescriptor(\Month.startDate, order: .forward)])
        if let month = try modelContainer.mainContext.fetch(descriptor).last {
            return month.detachedCopy()
        }
    } catch {
        print("Error fetching month budgets: \(error)")
    }
    return nil
}
