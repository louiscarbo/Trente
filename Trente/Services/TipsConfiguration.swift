//
//  TipsConfiguration.swift
//  Trente
//

import TipKit

@MainActor
enum TipsConfiguration {
    static func start() {
        #if DEBUG
        if StoreCapture.isEnabled || isRunningTests {
            Tips.hideAllTipsForTesting()
        }
        #endif
        try? Tips.configure()
    }

    #if DEBUG
    private static var isRunningTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }
    #endif
}
