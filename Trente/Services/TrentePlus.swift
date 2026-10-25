//
//  TrentePlus.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 26/04/2025.
//

import StoreKit

enum TrentePlus: Hashable {
    case monthly
    case annual
    
    static let groupID = "21676268"

    static func isActive(_ states: [Product.SubscriptionInfo.RenewalState]) -> Bool {
        states.contains { state in
            state == .subscribed || state == .inGracePeriod
        }
    }
    
    init?(_ product: Product) {
        switch product.id {
        case Self.monthly.id:
            self = .monthly
        case Self.annual.id:
            self = .annual
        default:
            return nil
        }
    }
    
    var id: String {
        switch self {
        case .monthly: return "TrentePlus"
        case .annual: return "TrentePlusYearly"
        }
    }
}
