//
//  TrenteGroupBoxStyle.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 22/04/2025.
//

import SwiftUI

struct TrenteGroupBoxStyle: GroupBoxStyle {
    @Environment(\.colorScheme) var colorScheme
    
    var scaleHorizontally: Bool = true
    var scaleVertically: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // 1a) Style the label
            configuration.label
                .font(.headline)
                .foregroundColor(.primary)
            
            // 1b) Show the content
            if scaleHorizontally && scaleVertically {
                configuration.content
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if scaleVertically {
                configuration.content
                    .frame(maxHeight: .infinity)
            } else if scaleHorizontally {
                configuration.content
                    .frame(maxWidth: .infinity)
            } else {
                configuration.content
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 26)
                .fill(.regularMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 26)
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
