//
//  StyleCommons.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 01/07/2025.
//

import SwiftUI

extension View {
    /// Applies `.glassEffect` on iOS 26+, otherwise scales when pressed.
    @ViewBuilder
    func glassOrScale(isPressed: Bool, isEnabled: Bool, in shape: some Shape) -> some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            self.glassEffect(.regular.interactive(isEnabled), in: shape)
        } else {
            #if os(iOS)
            self.scaleEffect(isPressed ? 1.05 : 1)
            #else
            self
            #endif
        }
    }

    @ViewBuilder
    func glassEffectIfAvailable(isEnabled: Bool, in shape: some Shape) -> some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            self.glassEffect(.regular.interactive(isEnabled), in: shape)
        } else {
            self
        }
    }
}
