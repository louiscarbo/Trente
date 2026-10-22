//
//  RecurrenceView.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 14/07/2025.
//

import SwiftUI

struct RecurrenceView: View {
    // Transaction Data
    @Binding var recurrenceFrequency: RecurrenceFrequency
    @Binding var recurrenceStartDate: Date
    @Binding var recurrenceEndDate: Date?
    @Binding var isFirstOccurrenceAlreadyPaid: Bool
    var transactionType: TransactionType
    
    // View State
    private var minimumEndDate: Date {
        Calendar.current.date(byAdding: .day, value: 7, to: recurrenceStartDate) ?? recurrenceStartDate
    }
    
    var body: some View {
        ScrollView {
            GroupBox(label: Label("Recurrence Details", systemImage: "calendar")) {
                VStack(spacing: .medium) {
                    frequencyPicker
                    startDatePicker
                    if Calendar.current.isDateInToday(recurrenceStartDate) {
                        alreadyPaidToggle
                    }
                    endDatePicker
                }
            }
            .groupBoxStyle(TrenteGroupBoxStyle())
            .padding()
        }
    }
    
    private var frequencyPicker: some View {
        LabeledPicker(
            title: "Frequency",
            selection: $recurrenceFrequency,
            options: RecurrenceFrequency.allCases
        ) { frequency in
            Text(frequency.displayName)
        }
    }
    
    private var startDatePicker: some View {
        DatePicker(
            "Start Date",
            selection: $recurrenceStartDate,
            in: Calendar.current.startOfDay(for: .now)...,
            displayedComponents: .date
        )
        .datePickerStyle(.compact)
    }

    private var alreadyPaidToggle: some View {
        Toggle(isOn: $isFirstOccurrenceAlreadyPaid) {
            Text(transactionType == .income ? "Already received today" : "Already paid today")
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .toggleStyle(TrenteToggleStyle())
    }
    
    @ViewBuilder
    private var endDatePicker: some View {
        if recurrenceEndDate == nil {
            Button("Add an End Date") {
                withAnimation(.bouncy) {
                    recurrenceEndDate = recurrenceStartDate
                }
            }
            .buttonStyle(TrentePrimaryButtonStyle(narrow: true))
        } else {
            HStack {
                DatePicker(
                    "End Date",
                    selection: Binding<Date>(
                        get: { recurrenceEndDate! },
                        set: { recurrenceEndDate = $0 }
                    ),
                    in: minimumEndDate...,
                    displayedComponents: .date
                )
                
                Button {
                    withAnimation(.bouncy) {
                        recurrenceEndDate = nil
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                }
                .tint(.primary)
            }
        }
    }
}

#Preview {
    @Previewable @State var recurrenceFrequency: RecurrenceFrequency = .monthly
    @Previewable @State var recurrenceStartDate: Date = Date()
    @Previewable @State var recurrenceEndDate: Date?
    @Previewable @State var isFirstOccurrenceAlreadyPaid = true
    
    Text("Hello")
        .sheet(isPresented: .constant(true)) {
            NavigationStack {
                RecurrenceView(
                    recurrenceFrequency: $recurrenceFrequency,
                    recurrenceStartDate: $recurrenceStartDate,
                    recurrenceEndDate: $recurrenceEndDate,
                    isFirstOccurrenceAlreadyPaid: $isFirstOccurrenceAlreadyPaid,
                    transactionType: .expense
                )
                .navigationTitle("New Transaction")
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                #endif
            }
        }
}
