//
//  SidebarRowButtonStyle.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 27/10/2026.
//

import SwiftUI

struct SidebarRowButtonStyle<PressedShape: Shape>: ButtonStyle {
    let pressedShape: PressedShape
    var drawsBehindContent = false

    func makeBody(configuration: Configuration) -> some View {
        SidebarRowPressedOverlay(
            isPressed: configuration.isPressed,
            shape: pressedShape,
            drawsBehindContent: drawsBehindContent
        ) {
            configuration.label
        }
    }
}

private struct SidebarRowPressedOverlay<PressedShape: Shape, Content: View>: View {
    let isPressed: Bool
    let shape: PressedShape
    let drawsBehindContent: Bool
    @ViewBuilder let content: Content

    var body: some View {
        content
            .contentShape(.rect)
            .background {
                if drawsBehindContent { pressedFill }
            }
            .overlay {
                if !drawsBehindContent { pressedFill }
            }
            .animation(.easeOut, value: isPressed)
    }

    private var pressedFill: some View {
        shape
            .fill(.primary.opacity(0.1))
            .opacity(isPressed ? 1 : 0)
            .allowsHitTesting(false)
    }
}
