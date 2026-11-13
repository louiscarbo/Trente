//
//  SubscriptionView.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 26/04/2025.
//

import SwiftUI
import StoreKit

struct SubscriptionView: View {
    var showsOptionalNote = false

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        SubscriptionStoreView(groupID: TrentePlus.groupID) {
            MarketingHeader(showsOptionalNote: showsOptionalNote)
        }
        .subscriptionStoreControlStyle(.compactPicker)
        .storeButton(.visible, for: .cancellation, .restorePurchases, .policies, .redeemCode)
        .subscriptionStorePolicyDestination(url: ExternalLinks.privacyPolicy, for: .privacyPolicy)
        .subscriptionStorePolicyDestination(url: ExternalLinks.termsOfUse, for: .termsOfService)
        .onInAppPurchaseCompletion { _, result in
            if case .success(.success) = result {
                await TrentePlusStatus.shared.refresh()
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
