//
//  AppIconSwitcher.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 29/10/2026.
//

#if os(iOS)
import UIKit

@MainActor
enum AppIconSwitcher {
    static let primary = AppIcon.primary(in: Bundle.main.infoDictionary)

    static var isAvailable: Bool {
        UIApplication.shared.supportsAlternateIcons
    }

    static var current: AppIcon {
        AppIcon(alternateIconName: UIApplication.shared.alternateIconName, primary: primary)
    }

    static func apply(_ icon: AppIcon) async throws {
        let alternateIconName = icon.alternateIconName(primary: primary)
        guard UIApplication.shared.alternateIconName != alternateIconName else { return }
        try await UIApplication.shared.setAlternateIconName(alternateIconName)
    }
}
#endif
