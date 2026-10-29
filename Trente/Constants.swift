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
    static let help = "help"
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

    static let manageSubscriptions = URL(string: "https://apps.apple.com/account/subscriptions")!
    static let ccBy3License = URL(string: "https://creativecommons.org/licenses/by/3.0/")!
    static let piggySavingsIcon = URL(string: "https://thenounproject.com/icon/piggy-savings-5860187/")!
    static let financialStartupIcon = URL(string: "https://thenounproject.com/icon/financial-startup-5860236/")!
    static let developerWebsite = URL(string: "https://carbo-estaque.fr")!
    static let privacyPolicy = URL(string: "https://carbo-estaque.fr/trente/privacy")!
    static let termsOfUse = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    static let developerLinkedIn = URL(string: "https://www.linkedin.com/in/louis-carbo-estaque/")!
    static let developerGitHub = URL(string: "https://github.com/louiscarbo")!
}
