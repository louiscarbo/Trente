//
//  TitleView.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 12/07/2025.
//

import SwiftUI

private struct TitleView: View {
    // Transaction Data
    @Binding var title: String
    
    // View Bindings
    @Binding var nextButtonDisabled: Bool
    @Binding var step: NewTransactionStep
    @Binding var showKeyboardDismissButton: Bool
    
    // View Logic
    @FocusState private var titleFieldIsFocused: Bool
    
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
                .font(.system(size: 40, weight: .bold))
                .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
        .padding()
        .onChange(of: title) {
            updateNextButtonState()
        }
        .onChange(of: titleFieldIsFocused) { _, newValue in
            if newValue == true {
                showKeyboardDismissButton = true
            } else {
                showKeyboardDismissButton = false
            }
        }
        .onAppear {
            updateNextButtonState()
            titleFieldIsFocused = true
        }
        .onChange(of: step) { _, newStep in
            if newStep != .title {
                titleFieldIsFocused = false
            }
        }
    }
    
    private func updateNextButtonState() {
        if title.isEmpty {
            nextButtonDisabled = true
        } else {
            nextButtonDisabled = false
        }
    }
}



#Preview {
    TitleView()
}
