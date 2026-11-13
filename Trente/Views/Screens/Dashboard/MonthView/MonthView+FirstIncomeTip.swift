//
//  MonthView+FirstIncomeTip.swift
//  Trente
//

import SwiftUI
import TipKit

extension MonthView {
    struct FirstIncomeTip: Tip {
        static let incomeAdded = Tips.Event(id: "firstIncomeAdded")

        var title: Text {
            Text("That's your first income")
        }

        var message: Text? {
            Text("Trente added it from your budget and will log it every month. Tap to change the day, edit it, or stop it.")
        }

        var image: Image? {
            Image(systemName: "arrow.triangle.2.circlepath")
        }

        var rules: [Rule] {
            #Rule(Self.incomeAdded) { $0.donations.count >= 1 }
        }

        var options: [any TipOption] {
            Tips.MaxDisplayCount(1)
        }
    }
}
