//
//  CardCarousel.swift
//  Trente
//

import SwiftUI

struct CardCarousel<Page: CaseIterable & Hashable, Card: View>: View where Page.AllCases: RandomAccessCollection {
    @Binding var selection: Page?
    var spacing: CGFloat = 20
    var safeAreaPadding = false
    @ViewBuilder var card: (Page) -> Card

    var body: some View {
        VStack(spacing: 8) {
            ScrollView(.horizontal) {
                HStack(spacing: spacing) {
                    ForEach(Page.allCases, id: \.self) { page in
                        card(page)
                            .containerRelativeFrame(.horizontal)
                            .id(page)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollIndicators(.hidden)
            .scrollPosition(id: $selection)
            .modify { view in
                if safeAreaPadding {
                    view
                        .safeAreaPadding(.horizontal)
                        .safeAreaPadding(.vertical, 3)
                } else {
                    view
                }
            }
            #if os(macOS)
            PageIndicator(currentPage: $selection)
            #endif
        }
    }
}
