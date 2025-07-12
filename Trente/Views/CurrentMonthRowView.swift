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
    @State private var isPressed: Bool = false
    var scaleVertically: Bool = false
    
    @Environment(\.colorScheme) var colorScheme
    private var lightMode: Bool { colorScheme == .light }

    private var isSelected: Bool { selectedMonth == currentMonth }
    
    var body: some View {
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
        .background(
            backgroundView
        )
        .onTapGesture {
            withAnimation(.easeOut) {
                selectedMonth = currentMonth
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
    
    var remainingSpentView: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Remaining")
                    .font(.subheadline)
                Text(currentMonth.remainingAmountDisplay)
                    .font(.title)
                    .foregroundColor(currentMonth.overSpent ? .red : .green)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text("Spent")
                    .font(.subheadline)
                Text(currentMonth.spentAmountDisplay)
                    .font(.title)
                    .foregroundColor(.red)
            }
        }
    }
    
    var backgroundView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 26)
                .foregroundStyle(
                    LinearGradient(
                        colors: [currentMonth.overSpent ? .red.opacity(0.6) : .green.opacity(0.6), .red.opacity(0.6)],
                        startPoint: .bottomLeading,
                        endPoint: .bottomTrailing
                    )
                )
            RoundedRectangle(cornerRadius: 26)
                .foregroundStyle(
                    RadialGradient(
                        colors: [lightMode ? .white : .black, .clear],
                        center: .top,
                        startRadius: 0,
                        endRadius: 500
                    )
                )
            RoundedRectangle(cornerRadius: 26)
                .foregroundStyle(.regularMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 26)
                        .stroke(isSelected ? Color.primary :
                                    (lightMode ? Color.black.opacity(0.2) : Color.white.opacity(0.2)), lineWidth: 3)
                )
            if isPressed {
                RoundedRectangle(cornerRadius: 26)
                    .fill(lightMode ? Color.black.opacity(0.1) : Color.white.opacity(0.1))
            }
        }
    }
}
