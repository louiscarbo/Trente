//
//  CurrentMonthRowView.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 23/04/2025.
//

import SwiftUI

struct CurrentMonthRowView: View {
    var currentMonth: Month
    @Binding var selectedMonth: Month?
    
    @Environment(\.colorScheme) var colorScheme
    private var lightMode: Bool { colorScheme == .light }

    private var isSelected: Bool { selectedMonth == currentMonth }
    
    var body: some View {
        Button {
            withAnimation(.easeOut) {
                selectedMonth = currentMonth
            }
        } label: {
            rowContent
        }
        .buttonStyle(
            SidebarRowButtonStyle(
                pressedShape: RoundedRectangle(cornerRadius: .large),
                drawsBehindContent: true
            )
        )
        .background(
            backgroundView
        )
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var rowContent: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("\(currentMonth.name)")
                    .font(.headline)
                Spacer()
                Text(currentMonth.overSpent ? "Over Budget" : "Under Budget")
            }
            
            Divider()
            
            remainingSpentView
        }
        .padding()
    }
    
    var remainingSpentView: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Remaining")
                    .font(.subheadline)
                Text(currentMonth.remainingAmountDisplay)
                    .font(.title)
                    .foregroundStyle(currentMonth.overSpent ? .red : .green)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text("Spent")
                    .font(.subheadline)
                Text(currentMonth.spentAmountDisplay)
                    .font(.title)
                    .foregroundStyle(.red)
            }
        }
    }
    
    var backgroundView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: DesignSystem.Radius.large.rawValue)
                .foregroundStyle(
                    LinearGradient(
                        colors: [currentMonth.overSpent ? .red.opacity(0.6) : .green.opacity(0.6), .red.opacity(0.6)],
                        startPoint: .bottomLeading,
                        endPoint: .bottomTrailing
                    )
                )
            RoundedRectangle(cornerRadius: DesignSystem.Radius.large.rawValue)
                .foregroundStyle(
                    RadialGradient(
                        colors: [lightMode ? .white : .black, .clear],
                        center: .top,
                        startRadius: 0,
                        endRadius: 500
                    )
                )
            RoundedRectangle(cornerRadius: DesignSystem.Radius.large.rawValue)
                .foregroundStyle(.regularMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: DesignSystem.Radius.large.rawValue)
                        .stroke(.primary.opacity(isSelected ? 0.5 : 0.2), lineWidth: 3)
                }
        }
    }
}

extension CurrentMonthRowView {
    init(currentMonth: Month) {
        self.init(currentMonth: currentMonth, selectedMonth: .constant(nil))
    }
}
