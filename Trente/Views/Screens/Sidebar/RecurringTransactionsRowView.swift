//
//  RecurringTransactionsRowView.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 23/10/2026.
//

import SwiftUI

struct RecurringTransactionsRowView: View {
    let activeCount: Int
    let isSelected: Bool
    var onSelect: () -> Void

    var body: some View {
        Button {
            withAnimation(.easeOut) {
                onSelect()
            }
        } label: {
            HStack {
                Label("Recurring Transactions", systemImage: "clock.arrow.circlepath")
                Spacer()
                Text("\(activeCount) active")
                    .foregroundStyle(.secondary)
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
            .padding()
        }
        .buttonStyle(SidebarRowButtonStyle(pressedShape: RoundedRectangle(cornerRadius: .large)))
        .background(TrenteListBackgroundView())
        .overlay {
            RoundedRectangle(cornerRadius: DesignSystem.Radius.large.rawValue)
                .stroke(.primary.opacity(0.5), lineWidth: 3)
                .opacity(isSelected ? 1 : 0)
        }
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    VStack {
        RecurringTransactionsRowView(activeCount: 5, isSelected: false) {}
        RecurringTransactionsRowView(activeCount: 2, isSelected: true) {}
    }
    .padding()
}
