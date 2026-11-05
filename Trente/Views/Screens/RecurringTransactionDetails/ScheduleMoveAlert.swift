//
//  ScheduleMoveAlert.swift
//  Trente
//

import SwiftUI

struct ScheduleMove: Identifiable {
    let rule: RecurringTransactionRule
    let startDate: Date

    var id: Date { startDate }

    var moveTitle: String {
        let day = Self.dayDescription(of: startDate, for: rule.frequency)
        switch rule.frequency {
        case .weekly:
            return String(localized: "Move to \(day) Each Week")
        case .monthly:
            return String(localized: "Move to the \(day) of the Month")
        case .yearly:
            return String(localized: "Move to \(day) Each Year")
        }
    }

    var stayTitle: String {
        let day = Self.dayDescription(of: rule.startDate, for: rule.frequency)
        switch rule.frequency {
        case .weekly:
            return String(localized: "Stay on \(day) Each Week")
        case .monthly:
            return String(localized: "Stay on the \(day) of the Month")
        case .yearly:
            return String(localized: "Stay on \(day) Each Year")
        }
    }

    private static func dayDescription(of date: Date, for frequency: RecurrenceFrequency) -> String {
        switch frequency {
        case .weekly:
            date.formatted(.dateTime.weekday(.wide))
        case .monthly:
            Calendar.current.component(.day, from: date).dayOfMonthString()
        case .yearly:
            date.formatted(.dateTime.month(.wide).day())
        }
    }
}

extension View {
    func scheduleMoveAlert(
        _ move: Binding<ScheduleMove?>,
        onMove: @escaping (ScheduleMove) -> Void,
        onKeep: @escaping () -> Void = {}
    ) -> some View {
        alert(
            move.wrappedValue.map { String(localized: "Change when “\($0.rule.title)” is due?") } ?? "",
            isPresented: Binding(
                get: { move.wrappedValue != nil },
                set: { isPresented in
                    if !isPresented { move.wrappedValue = nil }
                }
            ),
            presenting: move.wrappedValue
        ) { proposal in
            Button(proposal.moveTitle) {
                onMove(proposal)
            }
            Button(proposal.stayTitle, role: .cancel, action: onKeep)
        } message: { _ in
            Text("It was marked on a different day than planned.")
        }
    }
}
