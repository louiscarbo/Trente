//
//  TrenteGroupBoxStyle.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 22/04/2025.
//

import SwiftUI

struct TrenteGroupBoxStyle: GroupBoxStyle {
    @Environment(\.colorScheme) var colorScheme
    
    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            configuration.label
                .font(.headline)
                .foregroundColor(.primary)
            
            configuration.content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.large.rawValue)
                .fill(.regularMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.large.rawValue)
                .stroke(.primary.opacity(0.2), lineWidth: 3)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    VStack {
        HStack {
            GroupBox("Group Box") {
                Text("This is a group box")
            }
            .groupBoxStyle(TrenteGroupBoxStyle())
            GroupBox("Group Box") {
                Text("This is a group box")
            }
            .groupBoxStyle(TrenteGroupBoxStyle())
        }
        GroupBox("Group Box") {
            Text("This is a group box")
        }
        .groupBoxStyle(TrenteGroupBoxStyle())
    }
}
