//
//  AppInfo.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 24/10/2026.
//

import Foundation
#if os(iOS)
import UIKit
#endif

struct AppInfo: Equatable {
    let version: String
    let build: String
    let systemName: String
    let systemVersion: String

    var versionDescription: String {
        "\(version) (\(build))"
    }

    var systemDescription: String {
        "\(systemName) \(systemVersion)"
    }

    static func formattedSystemVersion(_ version: OperatingSystemVersion) -> String {
        let components = [version.majorVersion, version.minorVersion]
            + (version.patchVersion == 0 ? [] : [version.patchVersion])
        return components.map(String.init).joined(separator: ".")
    }

    @MainActor
    static var current: AppInfo {
        let infoDictionary = Bundle.main.infoDictionary ?? [:]
        return AppInfo(
            version: infoDictionary["CFBundleShortVersionString"] as? String ?? "?",
            build: infoDictionary["CFBundleVersion"] as? String ?? "?",
            systemName: currentSystemName,
            systemVersion: formattedSystemVersion(ProcessInfo.processInfo.operatingSystemVersion)
        )
    }

    @MainActor
    private static var currentSystemName: String {
        #if os(iOS)
        UIDevice.current.systemName
        #else
        "macOS"
        #endif
    }
}
