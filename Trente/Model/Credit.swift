//
//  Credit.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 24/10/2026.
//

import Foundation

struct Credit: Identifiable {
    let id: String
    let title: LocalizedStringResource
    let detail: LocalizedStringResource
    let url: URL?
}

struct CreditSection: Identifiable {
    let id: String
    let title: LocalizedStringResource
    let credits: [Credit]

    static let all: [CreditSection] = [
        CreditSection(
            id: "illustrations",
            title: "Illustrations",
            credits: [
                Credit(
                    id: "piggySavings",
                    title: "“Piggy Savings” by Vectors Market",
                    detail: "From Noun Project, licensed under CC BY 3.0. Adapted for the app icon and the pig sticker.",
                    url: ExternalLinks.piggySavingsIcon
                ),
                Credit(
                    id: "financialStartup",
                    title: "“Financial Startup” by Vectors Market",
                    detail: "From Noun Project, licensed under CC BY 3.0. Used for the rocket sticker.",
                    url: ExternalLinks.financialStartupIcon
                ),
                Credit(
                    id: "ccBy3",
                    title: "Creative Commons Attribution 3.0",
                    detail: "The license of both illustrations.",
                    url: ExternalLinks.ccBy3License
                )
            ]
        ),
        CreditSection(
            id: "fiftyThirtyTwenty",
            title: "The 50/30/20 Rule",
            credits: [
                Credit(
                    id: "allYourWorth",
                    title: "All Your Worth (2005)",
                    detail: "Popularized by Elizabeth Warren and Amelia Warren Tyagi.",
                    url: nil
                )
            ]
        ),
        CreditSection(
            id: "thanks",
            title: "Thanks",
            credits: [
                Credit(
                    id: "testers",
                    title: "TestFlight Testers",
                    detail: "Thanks to everyone who tested Trente on TestFlight.",
                    url: nil
                ),
                Credit(
                    id: "trenteVingt",
                    title: "TrenteVingt",
                    detail: "Trente is the successor of TrenteVingt (2023).",
                    url: nil
                )
            ]
        )
    ]
}
