//
//  TrentePrimaryButtonStyle.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 26/04/2025.
//

import SwiftUI

struct TrentePrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled: Bool

    var narrow: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .trentePrimaryCapsule(narrow: narrow, isPressed: configuration.isPressed)
            .glassEffect(.regular.interactive(isEnabled), in: .capsule)
    }
}

struct TrentePrimaryCapsule: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.isEnabled) private var isEnabled: Bool
    private var lightMode: Bool { colorScheme == .light }

    var narrow: Bool
    var isPressed: Bool
    var solidFill: Bool

    private var strokeOpacity: Double {
        isEnabled ? 0.6 : 0.3
    }

    func body(content: Content) -> some View {
        content
            .bold()
            .foregroundStyle(lightMode ? Color.white : Color.black)
            .opacity(isEnabled ? 1 : 0.5)
            .font(narrow ? .title3 : .title2)
            .padding(.vertical, narrow ? 5 : 16)
            .frame(maxWidth: .infinity)
            .background {
                fill
                    .overlay {
                        ZStack {
                            Capsule()
                                .inset(by: 1.5)
                                .stroke(
                                    lightMode
                                    ? Color.black.opacity(strokeOpacity)
                                    : Color.white.opacity(strokeOpacity),
                                    lineWidth: 3
                                )
                            if isPressed {
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
                    }
            }
    }

    @ViewBuilder
    private var fill: some View {
        if solidFill {
            Capsule()
                .fill(lightMode ? Color(white: 0.22) : Color(white: 0.9))
        } else {
            Capsule()
                .fill(.regularMaterial)
                .environment(\.colorScheme, lightMode ? .dark : .light)
        }
    }
}

extension View {
    func trentePrimaryCapsule(narrow: Bool = false, isPressed: Bool = false, solidFill: Bool = false) -> some View {
        modifier(TrentePrimaryCapsule(narrow: narrow, isPressed: isPressed, solidFill: solidFill))
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
