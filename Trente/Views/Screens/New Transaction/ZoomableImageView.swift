//
//  ZoomableImageView.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 26/04/2025.
//

import SwiftUI
#if canImport(UIKit)
import UIKit

struct ZoomableImageView: View {
    let image: Image
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()

            UIKitContainer(
                image: image,
                onDismiss: { dismiss() }
            )
            .ignoresSafeArea()

            // Dismiss button
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.title2)
                    .padding(4)
            }
            .padding(.top, 12)
            .padding(.trailing, 12)
            .accessibilityLabel(Text("Close"))
            .buttonBorderShape(.circle)
            .buttonStyle(.glass)
        }
    }
}
#endif
