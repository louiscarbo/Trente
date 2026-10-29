//
//  TrentePlusEntitlement.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 29/10/2026.
//

import Foundation

enum TrentePlusEntitlement {
    static let appGroupID = "group.com.louiscarboestaque.Trente"
    static let key = "trentePlus.isSubscribed"
    static let didChange = Notification.Name("TrentePlusEntitlementDidChange")

    static var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }

    static func cached(in defaults: UserDefaults = sharedDefaults) -> Bool {
        defaults.bool(forKey: key)
    }

    static func cache(_ isSubscribed: Bool, in defaults: UserDefaults = sharedDefaults) {
        defaults.set(isSubscribed, forKey: key)
    }
}
