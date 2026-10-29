//
//  MonthStartDatePicker.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 23/10/2026.
//

import SwiftUI

struct MonthStartDatePicker: View {
    @Binding var startDate: Date

    var body: some View {
        DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
            .datePickerStyle(.compact)
    }
}

#Preview {
    @Previewable @State var startDate: Date = .now

    MonthStartDatePicker(startDate: $startDate)
        .padding()
}
