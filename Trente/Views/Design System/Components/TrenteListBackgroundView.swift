//
//  TrenteListBackgroundView.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 24/10/2026.
//

import SwiftUI

struct TrenteListBackgroundView: View {
    @Environment(\.colorScheme) var colorScheme
    private var lightMode: Bool { colorScheme == .light }
    
    var body: some View {
        RoundedRectangle(cornerRadius: DesignSystem.Radius.large.rawValue)
            .foregroundStyle(.regularMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.large.rawValue)
                    .stroke(
                        lightMode ? Color.black.opacity(0.2) : Color.white.opacity(0.2), lineWidth: 3)
            )
    }
}
