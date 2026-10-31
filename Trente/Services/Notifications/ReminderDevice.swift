//
//  ReminderDevice.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 31/10/2026.
//

import Foundation

enum ReminderDevice {
    case iPhone
    case iPad
    case mac

    @MainActor
    static var current: ReminderDevice {
        #if os(macOS)
        .mac
        #else
        DeviceIdiom.isPhone ? .iPhone : .iPad
        #endif
    }
}
