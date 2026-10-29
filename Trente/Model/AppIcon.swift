//
//  AppIcon.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 29/10/2026.
//

import Foundation

enum AppIcon: String, CaseIterable, Identifiable {
    case green
    case grey
    case blue
    case orange
    case pink
    case midnight

    var id: Self { self }

    var iconName: String {
        "Trente \(rawValue.capitalized)"
    }

    var previewImageName: String {
        "App Icon \(rawValue.capitalized)"
    }

    var title: LocalizedStringResource {
        switch self {
        case .green: "Green"
        case .grey: "Gray"
        case .blue: "Blue"
        case .orange: "Orange"
        case .pink: "Pink"
        case .midnight: "Midnight"
        }
    }

    init?(iconName: String) {
        guard let icon = Self.allCases.first(where: { $0.iconName == iconName }) else { return nil }
        self = icon
    }

    init(alternateIconName: String?, primary: AppIcon) {
        self = alternateIconName.flatMap(AppIcon.init(iconName:)) ?? primary
    }

    func alternateIconName(primary: AppIcon) -> String? {
        self == primary ? nil : iconName
    }

    static func primary(in infoDictionary: [String: Any]?) -> AppIcon {
        let primaryIcon = bundleIcons(in: infoDictionary)?["CFBundlePrimaryIcon"] as? [String: Any]
        let iconName = primaryIcon?["CFBundleIconName"] as? String
        return iconName.flatMap(AppIcon.init(iconName:)) ?? .green
    }

    static func alternateIconNames(in infoDictionary: [String: Any]?) -> Set<String> {
        guard let alternateIcons = bundleIcons(in: infoDictionary)?["CFBundleAlternateIcons"] as? [String: Any] else { return [] }
        return Set(alternateIcons.keys)
    }

    private static func bundleIcons(in infoDictionary: [String: Any]?) -> [String: Any]? {
        infoDictionary?["CFBundleIcons"] as? [String: Any]
    }
}
