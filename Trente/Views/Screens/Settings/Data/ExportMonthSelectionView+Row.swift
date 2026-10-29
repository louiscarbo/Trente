//
//  ExportMonthSelectionView+Row.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 24/10/2026.
//

import SwiftUI

extension ExportMonthSelectionView {
    struct Row: View {
        let option: ExportMonthOption
        let isSelected: Bool
        let onToggle: () -> Void

        var body: some View {
            Button(action: onToggle) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(option.name)
                            .foregroundStyle(.primary)
                        Text("^[\(option.transactionCount) transaction](inflect: true)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .imageScale(.large)
                        .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
                        .accessibilityHidden(true)
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(isSelected ? .isSelected : [])
        }
    }
}
