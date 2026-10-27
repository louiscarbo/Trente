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
    @Environment(\.colorScheme) var colorScheme
    private var lightMode: Bool { colorScheme == .light }

    private var rowShape: UnevenRoundedRectangle {
        let radius = DesignSystem.Radius.large.rawValue
        let isFirst = month == archivedMonths.first
        let isLast = month == archivedMonths.last
        return UnevenRoundedRectangle(
            topLeadingRadius: isFirst ? radius : 0,
            bottomLeadingRadius: isLast ? radius : 0,
            bottomTrailingRadius: isLast ? radius : 0,
            topTrailingRadius: isFirst ? radius : 0
        )
    }

    var body: some View {
        Button(action: toggleSelection) {
            HStack {
                Text(month.name)
                Spacer()
                Text(month.overSpent ? "Over Budget" : "Under Budget")
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
                    .stroke(lightMode ? Color.black.opacity(0.5) : Color.white.opacity(0.5), lineWidth: 3)
            }
        }
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        
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
