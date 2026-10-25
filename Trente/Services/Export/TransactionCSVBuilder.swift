//
//  TransactionCSVBuilder.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 23/10/2026.
//

import Foundation

enum TransactionCSVBuilder {
    static let header = [
        "Date",
        "Month",
        "Title",
        "Type",
        "Category",
        "Amount",
        "Currency",
        "Recurring",
        "Note",
        "Transaction ID"
    ]

    private static let lineEnding = "\r\n"
    private static let charactersRequiringQuotes: Set<Unicode.Scalar> = ["\"", "\r", "\n"]

    static func header(for format: TransactionCSVFormat) -> [String] {
        format.includesNotes ? header : header.filter { column in column != "Note" }
    }

    static func csv(
        from rows: [TransactionExportRow],
        format: TransactionCSVFormat = TransactionCSVFormat(),
        timeZone: TimeZone = .current
    ) -> String {
        let calendar = exportCalendar(in: timeZone)
        let records = [header(for: format)] + sorted(rows).map { fields(for: $0, format: format, calendar: calendar) }
        return records
            .map { record in
                record
                    .map { field in escaped(field, separator: format.separator) }
                    .joined(separator: format.separator) + lineEnding
            }
            .joined()
    }

    static func monthText(for date: Date, timeZone: TimeZone = .current) -> String {
        monthText(for: date, calendar: exportCalendar(in: timeZone))
    }

    static func amountText(fromCents cents: Int, decimalSeparator: String = ".") -> String {
        let sign = cents < 0 ? "-" : ""
        let units = cents.magnitude / 100
        let fraction = cents.magnitude % 100
        let fractionText = fraction < 10 ? "0\(fraction)" : "\(fraction)"
        return "\(sign)\(units)\(decimalSeparator)\(fractionText)"
    }

    static func escaped(_ field: String, separator: String = ",") -> String {
        let needsQuotes = field.contains(separator)
            || field.unicodeScalars.contains(where: { charactersRequiringQuotes.contains($0) })
        guard needsQuotes else { return field }
        return "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }

    private static func sorted(_ rows: [TransactionExportRow]) -> [TransactionExportRow] {
        rows.sorted { lhs, rhs in
            if lhs.date != rhs.date {
                return lhs.date < rhs.date
            }
            let titleOrder = lhs.title.compare(rhs.title, options: [.caseInsensitive, .numeric])
            if titleOrder != .orderedSame {
                return titleOrder == .orderedAscending
            }
            if lhs.transactionID != rhs.transactionID {
                return lhs.transactionID.uuidString < rhs.transactionID.uuidString
            }
            return lhs.category.exportOrder < rhs.category.exportOrder
        }
    }

    private static func fields(
        for row: TransactionExportRow,
        format: TransactionCSVFormat,
        calendar: Calendar
    ) -> [String] {
        var fields = [
            dayText(for: row.date, calendar: calendar),
            monthText(for: row.monthStartDate, calendar: calendar),
            row.title,
            row.type.rawValue,
            row.category.exportName,
            amountText(fromCents: row.amountCents, decimalSeparator: format.decimalSeparator),
            row.currencyCode,
            row.isRecurring ? "yes" : ""
        ]
        if format.includesNotes {
            fields.append(row.note ?? "")
        }
        fields.append(row.transactionID.uuidString)
        return fields
    }

    private static func exportCalendar(in timeZone: TimeZone) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar
    }

    private static func dayText(for date: Date, calendar: Calendar) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return "\(monthText(from: components))-\(twoDigits(components.day))"
    }

    private static func monthText(for date: Date, calendar: Calendar) -> String {
        monthText(from: calendar.dateComponents([.year, .month], from: date))
    }

    private static func monthText(from components: DateComponents) -> String {
        "\(String(format: "%04d", components.year ?? 0))-\(twoDigits(components.month))"
    }

    private static func twoDigits(_ value: Int?) -> String {
        String(format: "%02d", value ?? 0)
    }
}

private extension BudgetCategory {
    var exportName: String {
        switch self {
        case .needs: "Needs"
        case .wants: "Wants"
        case .savingsAndDebts: "Savings and Debts"
        }
    }

    var exportOrder: Int {
        Self.allCases.firstIndex(of: self) ?? 0
    }
}
