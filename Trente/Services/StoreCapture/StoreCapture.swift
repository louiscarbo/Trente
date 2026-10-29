//
//  StoreCapture.swift
//  Trente
//

#if DEBUG
import Foundation
import SwiftData

@MainActor
enum StoreCapture {
    static let argument = "-storeCapture"
    static let darkArgument = "-storeCaptureDark"
    static let macWindowSize = CGSize(width: 1260, height: 800)

    static var isEnabled: Bool {
        ProcessInfo.processInfo.arguments.contains(argument)
    }

    static var isDark: Bool {
        ProcessInfo.processInfo.arguments.contains(darkArgument)
    }

    static func makeModelContainer() throws -> ModelContainer {
        let configuration = ModelConfiguration(schema: .trente, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        let container = try ModelContainer(for: .trente, migrationPlan: TrenteMigrationPlan.self, configurations: [configuration])
        let context = container.mainContext

        let rules = recurring.map(localized).map(makeRule)
        rules.forEach(context.insert)

        for monthsAgo in 0..<SampleData.monthCount {
            let month = makeMonth(monthsAgo: monthsAgo)
            context.insert(month)
            for group in month.transactionGroups {
                guard let rule = rules.first(where: { $0.title == group.title }) else { continue }
                group.recurringRule = rule
                group.recurringOccurrenceDate = group.addedDate
            }
        }

        try context.save()
        return container
    }

    private static var language: StoreCaptureLanguage { .current }

    private static func localized(_ transaction: SampleTransaction) -> SampleTransaction {
        SampleTransaction(
            title: language.localized(transaction.title),
            day: transaction.day,
            entries: transaction.entries.mapValues { $0 * language.amountScale },
            note: transaction.note.map(language.localized)
        )
    }

    private static func makeMonth(monthsAgo: Int) -> Month {
        let monthStart = SampleData.startDate(monthsAgo: monthsAgo)
        let month = Month(
            startDate: monthStart,
            currency: Currencies.currency(for: language.currencyCode)!,
            idealBudgetCents: idealBudgetCents * language.amountScale,
            idealRepartition: idealRepartition.mapValues { $0 * language.amountScale }
        )
        month.transactionGroups = (recurring + oneOffsByMonthsAgo[monthsAgo])
            .filter { monthsAgo > 0 || SampleData.date(day: $0.day, inMonthStartingAt: monthStart) <= .now }
            .map(localized)
            .map { SampleData.group(from: $0, in: month) }
        return month
    }

    private static func makeRule(from transaction: SampleTransaction) -> RecurringTransactionRule {
        let startDate = SampleData.date(
            day: transaction.day,
            inMonthStartingAt: SampleData.startDate(monthsAgo: SampleData.monthCount - 1)
        )
        let rule = RecurringTransactionRule(
            title: transaction.title,
            frequency: .monthly,
            startDate: startDate,
            repartition: transaction.entries,
            createdAt: startDate
        )
        rule.autoConfirm = true
        return rule
    }
}
#endif
