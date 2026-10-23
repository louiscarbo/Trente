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
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        SubscriptionStoreView(groupID: TrentePlus.groupID) {
            TrentePlusMarketingHeader()
        }
        .subscriptionStoreControlStyle(.compactPicker)
        .storeButton(.visible, for: .cancellation, .restorePurchases)
        .onInAppPurchaseCompletion { _, result in
            if case .success(.success) = result {
                dismiss()
            }
        }
    }
}

private struct TrentePlusMarketingHeader: View {
    var body: some View {
        VStack(spacing: .large) {
            StickerView(imageName: "Trente Pig Sticker")
                .frame(width: 120, height: 120)

            VStack(spacing: .small) {
                Text("Trente+")
                    .font(.largeTitle)
                    .bold()
                Text("Get more out of every month.")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: .medium) {
                feature("Notes and photos on your transactions", systemImage: "photo.on.rectangle")
                feature("Support an independent app", systemImage: "heart")
                feature("More features on the way", systemImage: "sparkles")
            }
        }
        .padding()
    }

    private func feature(_ title: LocalizedStringKey, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.headline)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    Text("Hello")
        .sheet(isPresented: .constant(true)) {
            SubscriptionView()
        }
}
