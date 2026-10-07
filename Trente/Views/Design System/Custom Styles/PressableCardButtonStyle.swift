//
//  PressableCardButtonStyle.swift
//  Trente
//

import SwiftUI

/// A button style for whole-card tap targets (gauge cards, daily spending card): scales
/// down slightly while pressed, with a short hold on release so quick taps still read clearly.
struct PressableCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        PressedCardScale(isPressed: configuration.isPressed) {
            configuration.label
        }
    }
}

private struct PressedCardScale<Content: View>: View {
    var isPressed: Bool
    @ViewBuilder var content: Content

    @State private var isScaledDown = false
    @State private var releaseTask: Task<Void, Never>?

    var body: some View {
        content
            .scaleEffect(isScaledDown ? 0.97 : 1)
            .animation(.spring(duration: 0.25), value: isScaledDown)
            .onChange(of: isPressed) { _, pressed in
                releaseTask?.cancel()
                if pressed {
                    isScaledDown = true
                } else {
                    releaseTask = Task {
                        try? await Task.sleep(for: .milliseconds(100))
                        guard !Task.isCancelled else { return }
                        isScaledDown = false
                    }
                }
            }
    }
}
