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

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(archivedMonths) { month in
                Row(
                    name: month.name,
                    isOverspent: month.overSpent,
                    isSelected: selectedMonth == month,
                    isFirst: month == archivedMonths.first,
                    isLast: month == archivedMonths.last
                ) {
                    withAnimation {
                        selectedMonth = month
                    }
                }
            }
        }
        .background(
            TrenteListBackgroundView()
        )
   }
}
