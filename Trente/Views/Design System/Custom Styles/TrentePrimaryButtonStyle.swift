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
                            .inset(by: 1.5)
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
                                        colors: [.black.opacity(0.05), .black.opacity(0.3)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                        }
                    }
                )
            configuration.label
                .bold()
                .foregroundStyle(lightMode ? Color.white : Color.black)
                .opacity(isEnabled ? 1 : 0.5)
                .font(narrow ? .title3 : .title2)
                .padding(.vertical, narrow ? 5 : 16)
        }
        .frame(maxWidth: .infinity)
        .fixedSize(horizontal: false, vertical: true)
        .environment(\.colorScheme, lightMode ? .dark : .light)
        .glassEffect(.regular.interactive(isEnabled), in: .capsule)
    }
}

#Preview {
    VStack {
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
        .background(.white)
        .environment(\.colorScheme, .light)
        
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
        .background(.black)
        .environment(\.colorScheme, .dark)
    }
}
