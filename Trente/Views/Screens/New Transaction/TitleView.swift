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
    @Binding var step: NewTransactionStep
    @Binding var showKeyboardDismissButton: Bool
    @FocusState private var titleFieldIsFocused: Bool
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
                .focused($titleFieldIsFocused)
                .textFieldStyle(.plain)
                .font(.system(size: titleFontSize, weight: .bold))
                .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
        .padding()
        .onChange(of: titleFieldIsFocused) { _, newValue in
            if newValue == true {
                showKeyboardDismissButton = true
            } else {
                showKeyboardDismissButton = false
            }
        }
        .onAppear {
            titleFieldIsFocused = true
        }
        .onChange(of: step) { _, newStep in
            if newStep != .title {
                titleFieldIsFocused = false
            }
        }
    }
}
