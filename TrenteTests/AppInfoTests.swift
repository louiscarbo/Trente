//
//  AppInfoTests.swift
//  TrenteTests
//
//  Created by Louis Carbo Estaque on 24/10/2026.
//

import Testing
import Foundation
@testable import Trente

struct AppInfoTests {

    private let appInfo = AppInfo(version: "1.0", build: "1", systemName: "iOS", systemVersion: "27.0")

    @Test("The version reads as the marketing version followed by the build")
    func versionDescription() {
        #expect(appInfo.versionDescription == "1.0 (1)")
    }

    @Test("The system reads as its name followed by its version")
    func systemDescription() {
        #expect(appInfo.systemDescription == "iOS 27.0")
    }

    @Test(
        "The system version drops a zero patch number",
        arguments: [
            (27, 0, 0, "27.0"),
            (27, 1, 0, "27.1"),
            (27, 1, 2, "27.1.2"),
            (27, 0, 1, "27.0.1")
        ]
    )
    func formattedSystemVersion(major: Int, minor: Int, patch: Int, expected: String) {
        let version = OperatingSystemVersion(majorVersion: major, minorVersion: minor, patchVersion: patch)

        #expect(AppInfo.formattedSystemVersion(version) == expected)
    }
}
