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

    @Test("The privacy policy lives on the developer website")
    func privacyPolicyHost() {
        #expect(ExternalLinks.privacyPolicy.host() == ExternalLinks.developerWebsite.host())
        #expect(ExternalLinks.privacyPolicy.path() == "/trente/privacy")
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
