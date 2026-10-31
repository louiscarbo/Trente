//
//  ExternalLinksTests.swift
//  TrenteTests
//
//  Created by Louis Carbo Estaque on 27/10/2026.
//

import Testing
import Foundation
@testable import Trente

struct ExternalLinksTests {

    @Test("The developer website is carbo-estaque.fr")
    func developerWebsite() {
        #expect(ExternalLinks.developerWebsite.absoluteString == "https://carbo-estaque.fr")
    }

    private static let privacyPolicyPages = [
        ("en", "https://trente.app/privacy/"),
        ("en-GB", "https://trente.app/en-gb/privacy/"),
        ("de", "https://trente.app/de/datenschutz/"),
        ("es", "https://trente.app/es/privacidad/"),
        ("es-419", "https://trente.app/es-419/privacidad/"),
        ("fr", "https://trente.app/fr/confidentialite/"),
        ("it", "https://trente.app/it/privacy/"),
        ("ko", "https://trente.app/ko/privacy/"),
        ("pt-BR", "https://trente.app/pt-br/privacidade/"),
        ("pt-PT", "https://trente.app/pt-pt/privacidade/")
    ]

    @Test("The privacy policy opens in each language of the app", arguments: privacyPolicyPages)
    func privacyPolicyPage(localization: String, expectedURL: String) {
        #expect(ExternalLinks.privacyPolicy(localization: localization).absoluteString == expectedURL)
    }

    @Test("The privacy policy opens in English for other languages", arguments: ["ja", "zh-Hans", "Base", ""])
    func privacyPolicyFallback(localization: String) {
        #expect(ExternalLinks.privacyPolicy(localization: localization).absoluteString == "https://trente.app/privacy/")
    }

    @Test("Every language the app ships is in the privacy policy table")
    func shippedLanguagesHavePrivacyPolicyPages() {
        let shippedLocalizations = Set(Bundle.main.localizations).subtracting(["Base"])
        #expect(shippedLocalizations == Set(Self.privacyPolicyPages.map(\.0)))
    }

    @Test("The privacy policy follows the language the app is running in")
    func privacyPolicyFollowsRunningLanguage() throws {
        let runningLocalization = try #require(Bundle.main.preferredLocalizations.first)
        #expect(ExternalLinks.privacyPolicy == ExternalLinks.privacyPolicy(localization: runningLocalization))
    }

    @Test("The terms of use are Apple's standard license agreement")
    func termsOfUse() {
        #expect(ExternalLinks.termsOfUse.host() == "www.apple.com")
        #expect(ExternalLinks.termsOfUse.path().contains("stdeula"))
    }

    @Test(
        "Legal links open over HTTPS",
        arguments: [ExternalLinks.privacyPolicy, ExternalLinks.termsOfUse]
    )
    func legalLinksUseHTTPS(url: URL) {
        #expect(url.scheme == "https")
    }
}
