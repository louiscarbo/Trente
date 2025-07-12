//
//  TrenteToggleStyle.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 25/04/2025.
//

import SwiftUI

struct TrenteToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack {
                Image(systemName: configuration.isOn
                      ? "checkmark.circle.fill"
                      : "circle")
                    .font(.title2)
                    .foregroundStyle(configuration.isOn
                                     ? .primary
                                     : .secondary)
                configuration.label
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(configuration.isOn
                                 ? "Enabled"
                                 : "Disabled"))
        .accessibilityValue(Text(configuration.isOn
                                ? "On"
                                : "Off"))
    }
}

#Preview {
    @Previewable @State var isOn = false
    
    Toggle(isOn: $isOn) {
        Text("Toggle Label")
    }
    .toggleStyle(TrenteToggleStyle())
}
