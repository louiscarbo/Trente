//
//  TrentePlusSection.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 24/10/2026.
//

import SwiftUI

struct TrentePlusSection: View {
    let isSubscribed: Bool
    let onDiscover: () -> Void
    let onManage: () -> Void

    @State private var subscribedPage: SubscribedPage?
    @State private var pageHeights: [SubscribedPage: CGFloat] = [:]
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private enum SubscribedPage: CaseIterable {
        case thanks, comparison
    }

    var body: some View {
        Section {
            Group {
                if isSubscribed {
                    subscribedCarousel
                } else {
                    discoverCard
                }
            }
            .listRowInsets(EdgeInsets())
        } header: {
            Text("Trente+")
        }
    }

    private var discoverCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            note("I make Trente on my own, in my spare time, without ads or collecting your data. Trente+ helps me keep going, and gives you a few extras.")
                .padding(.bottom, 8)
            ComparisonTable(comparisons: TrentePlusBenefit.comparisons)
            Button("See Plans", action: onDiscover)
                .buttonStyle(TrentePrimaryButtonStyle())
                .padding()
        }
    }

    private var subscribedCarousel: some View {
        CardCarousel(selection: $subscribedPage) { page in
            pageContent(page)
                .fixedSize(horizontal: false, vertical: true)
                .onGeometryChange(for: CGFloat.self) { proxy in
                    proxy.size.height
                } action: { height in
                    pageHeights[page] = height
                }
                .frame(height: visiblePageHeight, alignment: .top)
                .clipped()
                .accessibilityHidden(isOffScreen(page))
        }
        .animation(.default, value: subscribedPage)
        .padding(.bottom, 12)
    }

    private var visiblePageHeight: CGFloat? {
        guard !dynamicTypeSize.isAccessibilitySize else { return nil }
        return pageHeights[subscribedPage ?? .thanks]
    }

    private func isOffScreen(_ page: SubscribedPage) -> Bool {
        !dynamicTypeSize.isAccessibilitySize && page != (subscribedPage ?? .thanks)
    }

    @ViewBuilder
    private func pageContent(_ page: SubscribedPage) -> some View {
        let isStacked = dynamicTypeSize.isAccessibilitySize
        switch page {
        case .thanks:
            VStack(alignment: .leading, spacing: 0) {
                note("Thank you for subscribing to Trente+! Your subscription is what lets me keep working on Trente on my own, without ads or data collection.")
                if !isStacked {
                    manageButton
                }
            }
        case .comparison:
            VStack(alignment: .leading, spacing: 0) {
                if !isStacked {
                    Text("You have everything in the Trente+ column.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding([.horizontal, .top])
                        .padding(.bottom, 4)
                }
                ComparisonTable(comparisons: TrentePlusBenefit.comparisons)
                manageButton
            }
        }
    }

    private var manageButton: some View {
        Button("Manage Subscription", action: onManage)
            .buttonStyle(TrenteSecondaryButtonStyle())
            .padding()
    }

    private func note(_ message: LocalizedStringResource) -> some View {
        SignedNote(
            message: message,
            signature: "Louis",
            portraitName: DeveloperProfile.louis.photoName
        )
    }
}

#Preview {
    Form {
        TrentePlusSection(isSubscribed: false, onDiscover: {}, onManage: {})
        TrentePlusSection(isSubscribed: true, onDiscover: {}, onManage: {})
    }
    .formStyle(.grouped)
}
