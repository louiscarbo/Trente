//
//  TrenteVingtImporter.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 03/11/2026.
//

import Foundation
import SwiftData

struct TrenteVingtImporter {
    private struct NewMonth {
        let source: TrenteVingtExport.Month
        let startDate: Date
        let currency: Currency
    }

    private struct Plan {
        var months: [NewMonth] = []
        var skippedMonths: [TrenteVingtExport.Month] = []
        var rules: [TrenteVingtExport.RecurringTransaction] = []

        var summary: TrenteVingtImportSummary {
            TrenteVingtImportSummary(
                monthCount: months.count,
                transactionCount: months.reduce(0) { $0 + $1.source.transactions.count },
                recurringTransactionCount: rules.count,
                skippedMonthCount: skippedMonths.count,
                skippedTransactionCount: skippedMonths.reduce(0) { $0 + $1.transactions.count }
            )
        }
    }

    private static let largestAmount = 1e12

    var calendar: Calendar = .current
    var now: Date = .now

    func preview(of export: TrenteVingtExport, in context: ModelContext) throws -> TrenteVingtImportSummary {
        try makePlan(of: export, in: context).summary
    }

    @discardableResult
    func importData(_ export: TrenteVingtExport, into context: ModelContext) throws -> TrenteVingtImportSummary {
        let plan = try makePlan(of: export, in: context)
        for newMonth in plan.months {
            insert(newMonth, in: context)
        }
        let latestMonth = export.months.max { $0.creationDate < $1.creationDate }
        for exportedRule in plan.rules {
            guard let rule = makeRule(from: exportedRule, splitLike: latestMonth) else { continue }
            context.insert(rule)
        }
        do {
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
        return plan.summary
    }

    func startDate(of month: TrenteVingtExport.Month, startDay: Int) -> Date {
        let anchor = month.transactions.map(\.date).min() ?? month.creationDate
        let anchorYear = calendar.component(.year, from: anchor)
        let day = min(max(startDay, 1), 28)
        let candidates = (anchorYear - 1...anchorYear + 1).flatMap { year in
            [month.monthNumber, month.monthNumber - 1].compactMap { monthNumber in
                calendar.date(from: DateComponents(year: year, month: monthNumber, day: day))
            }
        }
        func score(_ candidate: Date) -> (Int, TimeInterval) {
            let endDate = calendar.date(byAdding: .month, value: 1, to: candidate) ?? candidate
            return (
                month.transactions.filter { candidate <= $0.date && $0.date < endDate }.count,
                -abs(candidate.timeIntervalSince(anchor))
            )
        }
        return candidates.max { score($0) < score($1) } ?? calendar.startOfDay(for: anchor)
    }

    func split(_ cents: Int, like month: TrenteVingtExport.Month?) -> [BudgetCategory: Int] {
        let needs = month?.needsPercentage ?? 50
        let wants = month?.wantsPercentage ?? 30
        let savings = month?.savingsPercentage ?? 20
        let total = needs + wants + savings
        guard total > 0, min(needs, wants, savings) >= 0 else { return [.needs: cents] }
        let unitCents = month.flatMap { Currencies.currency(for: $0.currencyCode) }?.fractionDigits == 0 ? 100 : 1
        let needsCents = share(needs / total, of: cents, inUnitsOf: unitCents)
        let wantsCents = min(share(wants / total, of: cents, inUnitsOf: unitCents), cents - needsCents)
        return [.needs: needsCents, .wants: wantsCents, .savingsAndDebts: cents - needsCents - wantsCents]
    }

    private func share(_ fraction: Double, of cents: Int, inUnitsOf unitCents: Int) -> Int {
        Int((Double(cents) * fraction / Double(unitCents)).rounded()) * unitCents
    }

    private func makePlan(of export: TrenteVingtExport, in context: ModelContext) throws -> Plan {
        let existingMonths = try context.fetch(FetchDescriptor<Month>())
        let existingMonthIDs = Set(existingMonths.map(\.id))
        let existingRuleIDs = Set(try context.fetch(FetchDescriptor<RecurringTransactionRule>()).map(\.id))
        var takenDates = existingMonths.map(\.dateInterval)
        var plan = Plan()

        let monthsToImport = export.months
            .filter { !existingMonthIDs.contains($0.id) }
            .sorted { $0.creationDate < $1.creationDate }
        for exportedMonth in monthsToImport {
            let startDate = startDate(of: exportedMonth, startDay: export.monthStartDay)
            guard let currency = Currencies.currency(for: exportedMonth.currencyCode),
                  let endDate = calendar.date(byAdding: .month, value: 1, to: startDate),
                  !takenDates.contains(where: { $0.start < endDate && startDate < $0.end })
            else {
                plan.skippedMonths.append(exportedMonth)
                continue
            }
            takenDates.append(DateInterval(start: startDate, end: endDate))
            plan.months.append(NewMonth(source: exportedMonth, startDate: startDate, currency: currency))
        }

        plan.rules = export.recurringTransactions.filter {
            !existingRuleIDs.contains($0.id) && cents(of: $0.amount) != 0 && anchorDate(of: $0) != nil
        }
        return plan
    }

    private func insert(_ newMonth: NewMonth, in context: ModelContext) {
        let source = newMonth.source
        let budgetCents = max(cents(of: source.budget), 0)
        let budgetSplit = split(budgetCents, like: source)
        let month = Month(
            startDate: newMonth.startDate,
            currency: newMonth.currency,
            idealBudgetCents: budgetCents,
            idealRepartition: budgetSplit
        )
        month.id = source.id
        context.insert(month)
        insertGroup(
            title: String(localized: "Income"),
            addedDate: newMonth.startDate,
            repartition: budgetSplit,
            into: month,
            in: context
        )
        for transaction in source.transactions {
            insertGroup(
                title: transaction.title,
                addedDate: transaction.date,
                repartition: repartition(amount: transaction.amount, category: transaction.category, splitLike: source),
                into: month,
                in: context
            )
        }
    }

    private func insertGroup(
        title: String,
        addedDate: Date,
        repartition: [BudgetCategory: Int],
        into month: Month,
        in context: ModelContext
    ) {
        let entries = repartition.filter { $0.value != 0 }
        guard !entries.isEmpty else { return }
        let group = TransactionGroup(
            title: title,
            type: entries.values.reduce(0, +) < 0 ? .expense : .income,
            month: month,
            note: nil,
            imageAttachmentData: nil,
            addedDate: addedDate
        )
        context.insert(group)
        for (category, amountCents) in entries {
            context.insert(TransactionEntry(amountCents: amountCents, category: category, group: group))
        }
    }

    private func repartition(
        amount: Double,
        category: TrenteVingtExport.Category,
        splitLike month: TrenteVingtExport.Month?
    ) -> [BudgetCategory: Int] {
        let amountCents = cents(of: amount)
        switch category {
        case .income: return split(abs(amountCents), like: month)
        case .needs: return [.needs: amountCents]
        case .wants: return [.wants: amountCents]
        case .savingsAndDebts: return [.savingsAndDebts: amountCents]
        }
    }

    private func makeRule(
        from exportedRule: TrenteVingtExport.RecurringTransaction,
        splitLike month: TrenteVingtExport.Month?
    ) -> RecurringTransactionRule? {
        guard let startDate = anchorDate(of: exportedRule) else { return nil }
        let rule = RecurringTransactionRule(
            title: exportedRule.title,
            frequency: exportedRule.frequency,
            startDate: startDate,
            repartition: repartition(amount: exportedRule.amount, category: exportedRule.category, splitLike: month)
                .filter { $0.value != 0 },
            createdAt: now
        )
        rule.id = exportedRule.id
        return rule
    }

    private func anchorDate(of exportedRule: TrenteVingtExport.RecurringTransaction) -> Date? {
        let today = calendar.startOfDay(for: now)
        switch exportedRule.frequency {
        case .weekly:
            guard let mondayBasedDay = exportedRule.day, (1...7).contains(mondayBasedDay) else { return nil }
            let weekday = mondayBasedDay % 7 + 1
            let daysSinceWeekday = (calendar.component(.weekday, from: today) - weekday + 7) % 7
            return calendar.date(byAdding: .day, value: -daysSinceWeekday, to: today)
        case .monthly:
            guard let dayOfMonth = exportedRule.day, (1...31).contains(dayOfMonth) else { return nil }
            return calendar.date(from: DateComponents(year: calendar.component(.year, from: today), month: 1, day: dayOfMonth))
        case .yearly:
            return exportedRule.startingDate.map { calendar.startOfDay(for: $0) }
        }
    }

    private func cents(of amount: Double) -> Int {
        guard abs(amount) < Self.largestAmount else { return 0 }
        return Int((amount * 100).rounded())
    }
}
