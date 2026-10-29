//
//  TrenteToggleStyle.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 25/04/2025.
//

import SwiftUI

struct TrenteToggleStyle: ToggleStyle {
    @State private var scale: CGFloat = 1.0
    
    func makeBody(configuration: Configuration) -> some View {
        Button {
            withAnimation(.bouncy) {
                configuration.isOn.toggle()
            }
        } label: {
            HStack {
                Image(systemName: configuration.isOn ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(configuration.isOn ? .primary : .secondary)
                    .onChange(of: configuration.isOn) { _, _ in
                        withAnimation(.spring(duration: 0.3)) {
                            scale = 1.05
                        } completion: {
                            withAnimation(.spring(duration: 0.3)) {
                                scale = 1.0
                            }
                        }
                    }
                    .scaleEffect(scale)
                
                configuration.label
                    .foregroundStyle(configuration.isOn ? .primary : .secondary)
            }
            .contentTransition(
                .symbolEffect(.replace)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    @Previewable @State var isOn = false
    
    Toggle(isOn: $isOn) {
        Text("Toggle Label")
    }
    .toggleStyle(TrenteToggleStyle())
}
