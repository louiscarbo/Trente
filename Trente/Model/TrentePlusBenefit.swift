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

    @MainActor
    static var all: [TrentePlusBenefit] {
        #if os(iOS)
        if DeviceIdiom.isPhone {
            [automaticRecurring, applePayLogging, notesAndImages, appIcons, supportIndieDeveloper]
        } else {
            [automaticRecurring, notesAndImages, appIcons, supportIndieDeveloper]
        }
        #else
        [automaticRecurring, notesAndImages, supportIndieDeveloper]
        #endif
    }

    private static let automaticRecurring = TrentePlusBenefit(
        id: "automaticRecurring",
        title: "Automatic recurring transactions",
        detail: "Rent, salary, subscriptions: added automatically, without you having to think about it.",
        systemImage: "arrow.triangle.2.circlepath",
        tint: .blue
    )

    private static let applePayLogging = TrentePlusBenefit(
        id: "applePayLogging",
        title: "Unlimited Apple Pay logging",
        detail: "Log every Apple Pay purchase, not just 10 a month.",
        systemImage: "creditcard.fill",
        tint: .green
    )

    private static let notesAndImages = TrentePlusBenefit(
        id: "notesAndImages",
        title: "Notes and images",
        detail: "Add a receipt, a photo or a note to your transactions.",
        systemImage: "photo",
        tint: .orange
    )

    private static let appIcons = TrentePlusBenefit(
        id: "appIcons",
        title: "App icons",
        detail: "Customize how Trente looks on your Home Screen.",
        systemImage: "paintpalette.fill",
        tint: .purple
    )

    private static let supportIndieDeveloper = TrentePlusBenefit(
        id: "supportIndieDeveloper",
        title: "Support an indie developer",
        detail: "Trente is designed and maintained entirely by one person.",
        systemImage: "heart.fill",
        tint: .red
    )
}
