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

    @State private var isPressed = false

    @Environment(\.colorScheme) private var colorScheme
    private var lightMode: Bool { colorScheme == .light }

    var body: some View {
        HStack {
            Label("Recurring Transactions", systemImage: "clock.arrow.circlepath")
            Spacer()
            Text("\(activeCount) active")
                .foregroundStyle(.secondary)
            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(TrenteListBackgroundView())
        .overlay {
            RoundedRectangle(cornerRadius: DesignSystem.Radius.large.rawValue)
                .stroke(lightMode ? Color.black.opacity(0.5) : Color.white.opacity(0.5), lineWidth: 3)
                .opacity(isSelected ? 1 : 0)
            RoundedRectangle(cornerRadius: DesignSystem.Radius.large.rawValue)
                .fill(lightMode ? Color.black.opacity(0.1) : Color.white.opacity(0.1))
                .opacity(isPressed ? 1 : 0)
        }
        .contentShape(.rect)
        .onTapGesture {
            withAnimation(.easeOut) {
                onSelect()
            }
        }
        .onLongPressGesture(
            minimumDuration: 0,
            pressing: { inProgress in
                withAnimation(.easeOut) {
                    isPressed = inProgress
                }
            },
            perform: { }
        )
    }
}

#Preview {
    VStack {
        RecurringTransactionsRowView(activeCount: 5, isSelected: false) {}
        RecurringTransactionsRowView(activeCount: 2, isSelected: true) {}
    }
    .padding()
}
