//
//  Constants.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 24/07/2025.
//

import Foundation
#if os(iOS)
import UIKit
#endif

enum WindowIdentifiers {
    static let newTransaction = "new-transaction"
    static let newMonth = "new-month"
}

enum ExternalLinks {
    static let logWalletTransactionShortcut = URL(string: "https://www.icloud.com/shortcuts/0c1436e878984b95a2e759409e587276")!
    static let writeReview = URL(string: "https://apps.apple.com/app/id6745130463?action=write-review")!

    static var notificationSettings: URL? {
        #if os(iOS)
        URL(string: UIApplication.openNotificationSettingsURLString)
        #else
        URL(string: "x-apple.systempreferences:com.apple.Notifications-Settings.extension")
        #endif
    }
}
