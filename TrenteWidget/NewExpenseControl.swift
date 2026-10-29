//
//  NewExpenseControl.swift
//  TrenteWidgetExtension
//
//  Created by Louis Carbo Estaque on 29/10/2026.
//

import AppIntents
import SwiftUI
import WidgetKit

struct NewExpenseControl: ControlWidget {
    let kind: String = "NewExpenseControl"

    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: kind) {
            ControlWidgetButton(action: OpenNewExpenseIntent()) {
                Label("New Expense", systemImage: "plus")
            }
        }
        .displayName("New Expense")
        .description("Opens Trente on a new expense.")
    }
}
