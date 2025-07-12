//
//  SubscriptionAccessible.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 26/04/2025.
//

import SwiftUI

struct SubscriptionAccessible: ViewModifier {
    let subscriptionIsActive: Bool
    
    func body(content: Content) -> some View {
        content
            .opacity(subscriptionIsActive ? 1 : 0.8)
            .contentShape(Rectangle())
            .allowsHitTesting(subscriptionIsActive)
            .blur(radius: subscriptionIsActive ? 0 : 3)
            .accessibilityHidden(!subscriptionIsActive)
    }
}

extension View {
    func subscriptionAccessible(subscribed subscriptionIsActive: Bool) -> some View {
        modifier(SubscriptionAccessible(subscriptionIsActive: subscriptionIsActive))
    }
}

#Preview {
    @Previewable @State var counter = 0
    @Previewable @State var isSubscribed = true
    
    Button("Toggle Subscription") {
        withAnimation {
            isSubscribed.toggle()
        }
    }
    
    VStack {
        Text("Counter: \(counter)")
        Button("Increase Counter") {
            counter += 1
        }
        .buttonStyle(TrenteSecondaryButtonStyle())
    }
    .subscriptionAccessible(subscribed: isSubscribed)
}
