//
//  StickerView.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 23/10/2026.
//

import SwiftUI

struct StickerView: View {
    let imageName: String
    var rotation: Angle = .degrees(-8)

    var body: some View {
        Image(imageName)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .rotationEffect(rotation)
            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
            .accessibilityHidden(true)
    }
}

#Preview {
    HStack {
        StickerView(imageName: "Trente Pig Sticker")
        StickerView(imageName: "Trente Rocket Sticker", rotation: .degrees(10))
    }
    .frame(height: 160)
    .padding()
}
