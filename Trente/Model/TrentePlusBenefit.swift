//
//  TrentePlusBenefit.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 29/10/2026.
//

import SwiftUI

struct TrentePlusBenefit: Identifiable {
    let id: String
    let title: LocalizedStringResource
    let detail: LocalizedStringResource
    let systemImage: String
    let tint: Color

    static var all: [TrentePlusBenefit] {
        #if os(iOS)
        [automaticRecurring, notesAndImages, appIcons, supportIndieDeveloper]
        #else
        [automaticRecurring, notesAndImages, supportIndieDeveloper]
        #endif
    }

    private static let automaticRecurring = TrentePlusBenefit(
        id: "automaticRecurring",
        title: "Automatic recurring transactions",
        detail: "Rent, salary, subscriptions: added on their due date, without a tap.",
        systemImage: "arrow.triangle.2.circlepath",
        tint: .blue
    )

    private static let notesAndImages = TrentePlusBenefit(
        id: "notesAndImages",
        title: "Notes and images",
        detail: "Attach receipts, photos and notes to any transaction.",
        systemImage: "photo",
        tint: .orange
    )

    private static let appIcons = TrentePlusBenefit(
        id: "appIcons",
        title: "App icons",
        detail: "Give Trente a new color on your Home Screen.",
        systemImage: "paintpalette.fill",
        tint: .purple
    )

    private static let supportIndieDeveloper = TrentePlusBenefit(
        id: "supportIndieDeveloper",
        title: "Support an indie developer",
        detail: "Trente is built and maintained by one person.",
        systemImage: "heart.fill",
        tint: .red
    )
}
