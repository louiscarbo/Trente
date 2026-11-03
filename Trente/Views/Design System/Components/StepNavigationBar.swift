//
//  StepNavigationBar.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 03/11/2026.
//

import SwiftUI

struct StepNavigationBar: View {
    let showsPrevious: Bool
    let nextTitle: LocalizedStringKey
    var canAdvance = true
    let onPrevious: () -> Void
    let onNext: () -> Void

    var body: some View {
        HStack(spacing: 20) {
            if showsPrevious {
                Button("Previous", action: onPrevious)
                    .buttonStyle(TrenteSecondaryButtonStyle(narrow: true))
            }
            Button(nextTitle, action: onNext)
                .disabled(!canAdvance)
                .buttonStyle(TrentePrimaryButtonStyle(narrow: true))
        }
        .padding()
        .bottomBarBackground()
    }
}

#Preview {
    VStack {
        Spacer()
        StepNavigationBar(showsPrevious: false, nextTitle: "Next", onPrevious: {}, onNext: {})
        StepNavigationBar(showsPrevious: true, nextTitle: "Create", canAdvance: false, onPrevious: {}, onNext: {})
    }
}
