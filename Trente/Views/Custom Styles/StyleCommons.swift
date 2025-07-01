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
    func glassOrScale(isPressed: Bool, isEnabled: Bool) -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(.regular.interactive(isEnabled))
        } else {
            self.scaleEffect(isPressed ? 1.05 : 1)
        }
    }
}
