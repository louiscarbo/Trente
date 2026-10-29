//
//  TrenteListBackgroundView.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 24/10/2026.
//

import SwiftUI

struct TrenteListBackgroundView: View {
    var body: some View {
        RoundedRectangle(cornerRadius: DesignSystem.Radius.large.rawValue)
            .foregroundStyle(SurfaceStyle.cardFill(tint: nil))
            .overlay {
                RoundedRectangle(cornerRadius: DesignSystem.Radius.large.rawValue)
                    .stroke(.primary.opacity(0.2), lineWidth: 3)
            }
    }
}
