//
//  ArchivedMonthsList.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 24/10/2026.
//

import SwiftUI

struct ArchivedMonthsList: View {
    @Binding var selectedMonth: Month?
    var archivedMonths: ArraySlice<Month>
    
    @Environment(\.colorScheme) var colorScheme
    private var lightMode: Bool { colorScheme == .light }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(archivedMonths) { month in
                MonthRowView(month: month, archivedMonths: archivedMonths, selectedMonth: $selectedMonth)
            }
        }
        .background(
            TrenteListBackgroundView()
        )
   }
}

private struct MonthRowView: View {
    var month: Month
    var archivedMonths: ArraySlice<Month>
    @Binding var selectedMonth: Month?
    
    var isSelected: Bool {
        selectedMonth == month
    }
    @State var isPressed: Bool = false
    
    @Environment(\.colorScheme) var colorScheme
    private var lightMode: Bool { colorScheme == .light }
    
    var body: some View {
        HStack {
            Text(month.name)
            Spacer()
            Text(month.overSpent ? "Over Budget" : "Under Budget")
            Image(systemName: "chevron.right")
                .foregroundStyle(Color.secondary)
        }
        .padding()
        .overlay {
            ZStack {
                if isSelected {
                    if month != archivedMonths.last && month != archivedMonths.first {
                        Rectangle()
                            .stroke(lightMode ? Color.black.opacity(0.5) : Color.white.opacity(0.5), lineWidth: 3)
                    } else if month == archivedMonths.first {
                        UnevenRoundedRectangle(
                            topLeadingRadius: DesignSystem.Radius.large.rawValue,
                            bottomLeadingRadius: 0,
                            bottomTrailingRadius: 0,
                            topTrailingRadius: DesignSystem.Radius.large.rawValue
                        )
                        .stroke(lightMode ? Color.black.opacity(0.5) : Color.white.opacity(0.5), lineWidth: 3)
                    } else {
                        UnevenRoundedRectangle(
                            topLeadingRadius: 0,
                            bottomLeadingRadius: DesignSystem.Radius.large.rawValue,
                            bottomTrailingRadius: DesignSystem.Radius.large.rawValue,
                            topTrailingRadius: 0
                        )
                        .stroke(lightMode ? Color.black.opacity(0.5) : Color.white.opacity(0.5), lineWidth: 3)
                    }
                }
                if isPressed {
                    if month != archivedMonths.last && month != archivedMonths.first {
                        Rectangle()
                            .fill(lightMode ? Color.black.opacity(0.1) : Color.white.opacity(0.1))
                    } else if month == archivedMonths.first {
                        UnevenRoundedRectangle(
                            topLeadingRadius: DesignSystem.Radius.large.rawValue,
                            bottomLeadingRadius: 0,
                            bottomTrailingRadius: 0,
                            topTrailingRadius: DesignSystem.Radius.large.rawValue
                        )
                        .fill(lightMode ? Color.black.opacity(0.1) : Color.white.opacity(0.1))
                    } else {
                        UnevenRoundedRectangle(
                            topLeadingRadius: 0,
                            bottomLeadingRadius: DesignSystem.Radius.large.rawValue,
                            bottomTrailingRadius: DesignSystem.Radius.large.rawValue,
                            topTrailingRadius: 0
                        )
                        .fill(lightMode ? Color.black.opacity(0.1) : Color.white.opacity(0.1))
                    }
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            toggleSelection()
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
        
        if month != archivedMonths.last {
            Divider()
        }
    }
    
    func toggleSelection() {
        withAnimation {
            selectedMonth = month
        }
    }
}
