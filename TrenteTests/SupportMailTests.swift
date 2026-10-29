//
//  SupportMailTests.swift
//  TrenteTests
//
//  Created by Louis Carbo Estaque on 24/10/2026.
//

import Testing
import Foundation
@testable import Trente

struct SupportMailTests {

    private let appInfo = AppInfo(version: "1.0", build: "1", systemName: "iOS", systemVersion: "27.0")

    @Test("The link is a mailto link to the given address")
    func schemeAndAddress() throws {
        let url = try #require(SupportMail.url(to: "hello@example.com", subject: "Hi", body: "Hello"))

        #expect(url.scheme == "mailto")
        #expect(url.absoluteString.hasPrefix("mailto:hello@example.com?"))
    }

    @Test("Spaces are encoded as %20")
    func spaces() throws {
        let url = try #require(SupportMail.url(to: "hello@example.com", subject: "Trente Feedback", body: "A B"))

        #expect(url.absoluteString == "mailto:hello@example.com?subject=Trente%20Feedback&body=A%20B")
    }

    @Test(
        "Characters with a meaning in a query are encoded",
        arguments: [
            ("&", "%26"),
            ("+", "%2B"),
            ("=", "%3D"),
            ("?", "%3F"),
            ("#", "%23"),
            ("\n", "%0A")
        ]
    )
    func reservedCharacters(character: String, encoded: String) throws {
        let url = try #require(SupportMail.url(to: "hello@example.com", subject: "Subject", body: "a\(character)b"))

        #expect(url.absoluteString.hasSuffix("&body=a\(encoded)b"))
    }

    @Test("The feedback body ends with the app and system versions")
    func feedbackBody() {
        let body = SupportMail.feedbackBody(appInfo: appInfo)

        #expect(body.hasSuffix("\nTrente 1.0 (1) · iOS 27.0"))
    }

    @Test("The feedback link goes to the support address")
    func feedbackURL() throws {
        let url = try #require(SupportMail.feedbackURL(appInfo: appInfo))

        #expect(url.absoluteString.hasPrefix("mailto:\(SupportMail.address)?subject="))
    }
}
