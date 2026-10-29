//
//  OnboardingScrollPane.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 23/10/2026.
//

import SwiftUI

struct OnboardingScrollPane<Content: View>: View {
    @ViewBuilder let content: () -> Content

    @Environment(\.isOnboardingLayoutRegular) private var isRegular

    var body: some View {
        ScrollView {
            VStack(spacing: .medium) {
                content()
            }
            .padding(.vertical, 3)
        }
        .scrollBounceBehavior(.basedOnSize)
        .defaultScrollAnchor(isRegular ? .center : .top, for: .alignment)
    }
}
