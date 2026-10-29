//
//  TitleView.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 12/07/2025.
//

import SwiftUI

struct TitleView: View {
    // Transaction Data
    @Binding var title: String
    
    // View State
    var focusedField: FocusState<NewTransactionField?>.Binding
    @ScaledMetric(relativeTo: .largeTitle) private var titleFontSize = 40
    
    var body: some View {
        VStack {
            HStack {
                Label("Give a title to your transaction", systemImage: "info.circle")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            
            Spacer()
            
            HStack(spacing: 0) {
                TextField(
                    "",
                    text: $title,
                    prompt: Text("Title"),
                    axis: .vertical
                )
                .lineLimit(3)
                .accessibilityLabel(Text("Title"))
                .focused(focusedField, equals: .title)
                .textFieldStyle(.plain)
                .font(.system(size: titleFontSize, weight: .bold))
                .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
        .padding()
        .onAppear {
            focusedField.wrappedValue = .title
        }
    }
}
