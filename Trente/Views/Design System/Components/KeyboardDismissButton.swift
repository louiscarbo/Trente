//
//  KeyboardDismissButton.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 14/05/2026.
//

import SwiftUI

private struct KeyboardDismissButtonModifier: ViewModifier {
    let isVisible: Bool
    let action: () -> Void

    func body(content: Content) -> some View {
        #if os(iOS)
        content
            .safeAreaInset(edge: .bottom) {
                if isVisible {
                    VStack {
                        Button(action: action) {
                            Label("Done", systemImage: "keyboard.chevron.compact.down")
                        }
                        .buttonStyle(TrenteSecondaryButtonStyle(narrow: true))
                    }
                    .padding()
                    .bottomBarBackground()
                }
            }
        #else
        content
        #endif
    }
}

extension View {
    func keyboardDismissButton(isVisible: Bool, action: @escaping () -> Void) -> some View {
        modifier(KeyboardDismissButtonModifier(isVisible: isVisible, action: action))
    }
}
