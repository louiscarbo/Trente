//
//  ArchivedMonthsList+Row.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 24/10/2026.
//

import SwiftUI

extension ArchivedMonthsList {
    struct Row: View {
        let name: String
        let isOverspent: Bool
        let isSelected: Bool
        let isFirst: Bool
        let isLast: Bool
        let onSelect: () -> Void

        private var rowShape: UnevenRoundedRectangle {
            let radius = DesignSystem.Radius.large.rawValue
            return UnevenRoundedRectangle(
                topLeadingRadius: isFirst ? radius : 0,
                bottomLeadingRadius: isLast ? radius : 0,
                bottomTrailingRadius: isLast ? radius : 0,
                topTrailingRadius: isFirst ? radius : 0
            )
        }

        var body: some View {
            Button(action: onSelect) {
                HStack {
                    Text(name)
                    Spacer()
                    Text(isOverspent ? "Over Budget" : "Under Budget")
                    Image(systemName: "chevron.right")
                        .foregroundStyle(Color.secondary)
                        .accessibilityHidden(true)
                }
                .padding()
            }
            .buttonStyle(SidebarRowButtonStyle(pressedShape: rowShape))
            .overlay {
                if isSelected {
                    rowShape
                        .stroke(.primary.opacity(0.5), lineWidth: 3)
                }
            }
            .accessibilityAddTraits(isSelected ? .isSelected : [])

            if !isLast {
                Divider()
            }
        }
    }
}
