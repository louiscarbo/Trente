//
//  AppIconTests.swift
//  TrenteTests
//
//  Created by Louis Carbo Estaque on 29/10/2026.
//

import Testing
import Foundation
#if os(iOS)
import UIKit
#else
import AppKit
#endif
@testable import Trente

struct AppIconTests {

    private let infoDictionary: [String: Any] = [
        "CFBundleIcons": [
            "CFBundlePrimaryIcon": ["CFBundleIconName": "Trente Grey"],
            "CFBundleAlternateIcons": [
                "Trente Green": ["CFBundleIconName": "Trente Green"],
                "Trente Blue": ["CFBundleIconName": "Trente Blue"]
            ]
        ]
    ]

    @Test("The primary icon is read from the bundle icons")
    func primaryFromInfoDictionary() {
        #expect(AppIcon.primary(in: infoDictionary) == .grey)
    }

    @Test("A bundle without icons falls back to green")
    func primaryFallback() {
        #expect(AppIcon.primary(in: nil) == .green)
        #expect(AppIcon.primary(in: [:]) == .green)
    }

    @Test("The alternate icon names are read from the bundle icons")
    func alternateIconNames() {
        #expect(AppIcon.alternateIconNames(in: infoDictionary) == ["Trente Green", "Trente Blue"])
        #expect(AppIcon.alternateIconNames(in: nil).isEmpty)
    }

    @Test("Choosing the primary icon resets to no alternate icon")
    func primaryHasNoAlternateName() {
        #expect(AppIcon.green.alternateIconName(primary: .green) == nil)
        #expect(AppIcon.green.alternateIconName(primary: .grey) == "Trente Green")
        #expect(AppIcon.pink.alternateIconName(primary: .green) == "Trente Pink")
    }

    @Test("The current icon is the alternate one, or the primary when there is none")
    func currentIcon() {
        #expect(AppIcon(alternateIconName: nil, primary: .green) == .green)
        #expect(AppIcon(alternateIconName: "Trente Midnight", primary: .green) == .midnight)
        #expect(AppIcon(alternateIconName: "Unknown", primary: .grey) == .grey)
    }

    @Test("Every icon has a preview image", arguments: AppIcon.allCases)
    func previewImageExists(icon: AppIcon) {
        #if os(iOS)
        #expect(UIImage(named: icon.previewImageName, in: .main, with: nil) != nil)
        #else
        #expect(Bundle.main.image(forResource: icon.previewImageName) != nil)
        #endif
    }

    #if os(iOS)
    @Test("Every icon ships as the primary icon or an alternate icon of the app")
    func everyIconIsInTheBundle() {
        let primary = AppIcon.primary(in: Bundle.main.infoDictionary)
        let alternateIconNames = AppIcon.alternateIconNames(in: Bundle.main.infoDictionary)

        #expect(primary == .green)
        for icon in AppIcon.allCases where icon != primary {
            #expect(alternateIconNames.contains(icon.iconName), "\(icon.iconName) is missing")
        }
    }
    #else
    @Test("The app ships with the green icon")
    func appIconIsGreen() {
        #expect(Bundle.main.object(forInfoDictionaryKey: "CFBundleIconName") as? String == AppIcon.green.iconName)
    }
    #endif
}
