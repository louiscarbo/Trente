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
            StickerView(imageName: "Trente Pig Sticker", rotation: .zero)
                .frame(width: 170)

            VStack(spacing: 6) {
                Text("Trente+")
                    .font(.largeTitle)
                    .bold()
                Text("Keep the full story of your spending, right next to the numbers.")
                    .foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.center)

            GroupBox(label: Label("What's included", systemImage: "sparkles")) {
                VStack(alignment: .leading, spacing: .medium) {
                    feature(
                        "Notes and images",
                        detail: "Attach receipts, photos and notes to any transaction."
                    )
                    feature(
                        "Support an indie developer",
                        detail: "Trente is built and maintained by one person."
                    )
                }
            }
            .groupBoxStyle(TrenteGroupBoxStyle())
        }
        .padding()
    }

    private func feature(_ title: LocalizedStringKey, detail: LocalizedStringKey) -> some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    Text("Hello")
        .sheet(isPresented: .constant(true)) {
            SubscriptionView()
        }
}

#Preview("Marketing Header", traits: .sizeThatFitsLayout) {
    TrentePlusMarketingHeader()
        .frame(width: 402)
}
