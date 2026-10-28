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
        PressedOverlay(
            isPressed: configuration.isPressed,
            shape: pressedShape,
            drawsBehindContent: drawsBehindContent
        ) {
            configuration.label
        }
    }
}
