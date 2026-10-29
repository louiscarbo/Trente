//
//  SkipOccurrenceConfirmation.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 27/10/2026.
//

import SwiftUI

extension View {
    func skipOccurrenceConfirmation(
        isPresented: Binding<Bool>,
        title: String,
        date: Date,
        frequency: RecurrenceFrequency,
        onSkip: @escaping () -> Void
    ) -> some View {
        let copy = SkipOccurrenceCopy(title: title, date: date, frequency: frequency)
        return confirmationDialog(
            copy.dialogTitle,
            isPresented: isPresented,
            titleVisibility: .visible
        ) {
            Button(copy.buttonTitle, role: .destructive, action: onSkip)
            Button(String(localized: "Cancel"), role: .cancel) {}
        } message: {
            Text(copy.message)
        }
    }
}

private struct SkipOccurrenceCopy {
    let title: String
    let date: Date
    let frequency: RecurrenceFrequency

    private var dayName: String { date.formatted(.dateTime.day().month(.wide)) }
    private var monthName: String { date.formatted(.dateTime.month(.wide)) }
    private var yearName: String { date.formatted(.dateTime.year()) }

    var dialogTitle: String {
        switch frequency {
        case .weekly:
            String(localized: "Skip “\(title)” on \(dayName)?")
        case .monthly:
            String(localized: "Skip “\(title)” for \(monthName)?")
        case .yearly:
            String(localized: "Skip “\(title)” in \(yearName)?")
        }
    }

    var buttonTitle: String {
        switch frequency {
        case .weekly:
            String(localized: "Skip on \(dayName)")
        case .monthly:
            String(localized: "Skip for \(monthName)")
        case .yearly:
            String(localized: "Skip in \(yearName)")
        }
    }

    var message: String {
        switch frequency {
        case .weekly:
            String(localized: "It won't be added that week. Next weeks aren't affected. You can't undo this.")
        case .monthly:
            String(localized: "It won't be added to \(monthName). Next months aren't affected. You can't undo this.")
        case .yearly:
            String(localized: "It won't be added in \(yearName). Next years aren't affected. You can't undo this.")
        }
    }
}
