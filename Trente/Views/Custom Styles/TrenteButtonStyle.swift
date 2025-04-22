//
//  TrenteButtonStyle.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 22/04/2025.
//

import SwiftUI

struct TrenteButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) var colorScheme
    private var lightMode: Bool { colorScheme == .light }

    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            Capsule()
                .fill(.regularMaterial)
                .overlay(
                    ZStack {
                        Capsule()
                            .stroke(
                                lightMode ? Color.black.opacity(configuration.isPressed ? 0.1 : 0.2) :
                                    Color.white.opacity(configuration.isPressed ? 0.1 : 0.2),
                                lineWidth: 3
                            )
                        if configuration.isPressed {
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: lightMode ?
                                        [.black.opacity(0.05), .black.opacity(0.1)] :
                                            [.white.opacity(0.05), .white.opacity(0.2)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                        }
                    }
                )
            configuration.label
                .font(.title2)
                .bold()
                .tint(.primary)
                .padding(.vertical)
        }
        .scaleEffect(configuration.isPressed ? 0.95 : 1)
    }
}

#Preview {
    VStack {
        Button("Test Button") {
            print("Button pressed")
        }
        .buttonStyle(TrenteButtonStyle())
        .frame(height: 50)
        .padding()
        
        Button {
            print("Button pressed")
        } label: {
            Label("Test Button", systemImage: "plus")
        }
        .buttonStyle(TrenteButtonStyle())
        .frame(height: 50)
        .padding()
    }
}
