//
//  SubscriptionView.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 26/04/2025.
//

import SwiftUI
import StoreKit

enum TrentePlus: Hashable {
    case monthly
    case annual
    
    static let groupID = "21676268"
    
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

struct SubscriptionView: View {
    var body: some View {
        
        // iOS 18 Store
        if #available(iOS 18.0, *) {
            SubscriptionStoreView(groupID: TrentePlus.groupID) {
                VStack {
                    Image("Trente Pig Sticker")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                    Text("Marketing Content Goes Here")
                }
            }
                .subscriptionStoreControlStyle(.compactPicker)
            
        // iOS 17
        } else {
            SubscriptionStoreView(groupID: TrentePlus.groupID)
        }
    }
}

#Preview {
    Text("Hello")
        .sheet(isPresented: .constant(true)) {
            SubscriptionView()
        }
}
