//
//  DeviceIdiom.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 25/10/2026.
//

import SwiftUI

enum DeviceIdiom {
    @MainActor
    static var isPhone: Bool {
        #if os(iOS)
        UIDevice.current.userInterfaceIdiom == .phone
        #else
        false
        #endif
    }
}
