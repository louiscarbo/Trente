//
//  SubscriptionView.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 26/04/2025.
//

import SwiftUI
import StoreKit

struct SubscriptionView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        SubscriptionStoreView(groupID: TrentePlus.groupID) {
            MarketingHeader()
        }
        .subscriptionStoreControlStyle(.compactPicker)
        .storeButton(.visible, for: .cancellation, .restorePurchases, .policies)
        .subscriptionStorePolicyDestination(url: ExternalLinks.privacyPolicy, for: .privacyPolicy)
        .subscriptionStorePolicyDestination(url: ExternalLinks.termsOfUse, for: .termsOfService)
        .onInAppPurchaseCompletion { _, result in
            if case .success(.success) = result {
                dismiss()
            }
        }
    }
}

#Preview {
    Text("Hello")
        .sheet(isPresented: .constant(true)) {
            SubscriptionView()
        }
}
