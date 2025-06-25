//
//  TrentePrimaryButtonStyle.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 26/04/2025.
//

import SwiftUI

struct TrentePrimaryButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.isEnabled) private var isEnabled: Bool
    private var lightMode: Bool { colorScheme == .light }
    
    var narrow: Bool = false
    var strokeOpacity: Double {
        isEnabled ? 0.6 : 0.3
    }

    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            Capsule()
                .fill(.regularMaterial)
                .overlay(
                    ZStack {
                        Capsule()
                            .stroke(
                                lightMode
                                ? Color.black.opacity(strokeOpacity)
                                : Color.white.opacity(strokeOpacity),
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
                .bold()
                .foregroundStyle(isEnabled ? Color.primary : Color.secondary)
                .font(.title2)
                .padding(.vertical, narrow ? 5 : 16)
        }
        .scaleEffect(configuration.isPressed ? 0.95 : 1)
        .fixedSize(horizontal: false, vertical: true)
        .environment(\.colorScheme, lightMode ? .dark : .light)
    }
}

#Preview {
    VStack {
        Button("Test Button") {
            print("Button pressed")
        }
        .buttonStyle(TrentePrimaryButtonStyle())
        .padding()
        .disabled(true)
        
        Button {
            print("Button pressed")
        } label: {
            Label("Test Button", systemImage: "plus")
        }
        .buttonStyle(TrentePrimaryButtonStyle())
        .padding()
    }
}
