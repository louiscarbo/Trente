//
//  Shapes.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 12/07/2025.
//

import SwiftUI

extension RoundedRectangle {
    init(cornerRadius: DesignSystem.Radius) {
        self.init(cornerRadius: cornerRadius.rawValue)
    }
}

extension VStack {
    init(
        alignment: HorizontalAlignment = .center,
        spacing: DesignSystem.Spacing,
        @ViewBuilder content: () -> Content
    ) {
        self.init(
            alignment: alignment,
            spacing: spacing.rawValue,
            content: content
        )
    }
}
