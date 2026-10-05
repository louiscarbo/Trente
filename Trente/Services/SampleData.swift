//
//  SampleData.swift
//  Trente
//

import Foundation

struct SampleTransaction {
    let title: String
    let day: Int
    let entries: [BudgetCategory: Int]
    var note: String?

    static func expense(
        _ title: String,
        day: Int,
        _ category: BudgetCategory,
        _ amountCents: Int
    ) -> SampleTransaction {
        SampleTransaction(title: title, day: day, entries: [category: -amountCents])
    }
}

enum SampleData {
    static let monthCount = 4
    static let currencyCode = "EUR"
    static let idealBudgetCents = 2500_00
    static let idealRepartition: [BudgetCategory: Int] = [
        .needs: 50,
        .wants: 30,
        .savingsAndDebts: 20
    ]

    static let recurring: [SampleTransaction] = [
        SampleTransaction(
            title: "Salary",
            day: 1,
            entries: [
                .needs: 1250_00,
                .wants: 750_00,
                .savingsAndDebts: 500_00
            ],
            note: "Monthly paycheck from Trente Inc."
        ),
        .expense("Rent", day: 2, .needs, 700_00),
        .expense("Livret A", day: 3, .savingsAndDebts, 400_00),
        .expense("Phone plan", day: 5, .needs, 19_99),
        .expense("Netflix", day: 15, .wants, 13_49)
    ]

    static let oneOffsByMonthsAgo: [[SampleTransaction]] = [
        [
            .expense("Supermarket", day: 3, .needs, 84_20),
            .expense("Bakery", day: 4, .wants, 6_80),
            .expense("Pharmacy", day: 6, .needs, 18_50),
            .expense("Supermarket", day: 10, .needs, 92_35),
            .expense("Restaurant", day: 11, .wants, 46_00),
            .expense("Train ticket", day: 12, .needs, 34_00),
            .expense("Cinema", day: 14, .wants, 23_50),
            .expense("Supermarket", day: 17, .needs, 78_90),
            .expense("Clothes", day: 19, .wants, 64_99),
            .expense("Electricity", day: 20, .needs, 58_40),
            .expense("Supermarket", day: 24, .needs, 88_10),
            .expense("Birthday gift", day: 26, .wants, 35_00)
        ],
        [
            .expense("Supermarket", day: 4, .needs, 91_60),
            .expense("Restaurant", day: 6, .wants, 52_30),
            .expense("Supermarket", day: 11, .needs, 85_75),
            .expense("Pharmacy", day: 13, .needs, 12_90),
            .expense("Concert tickets", day: 14, .wants, 78_00),
            .expense("Supermarket", day: 18, .needs, 96_40),
            .expense("Electricity", day: 20, .needs, 61_20),
            .expense("Clothes", day: 22, .wants, 129_99),
            .expense("Train ticket", day: 23, .needs, 41_00),
            .expense("Supermarket", day: 25, .needs, 73_85),
            .expense("Restaurant", day: 27, .wants, 38_50)
        ],
        [
            .expense("Supermarket", day: 3, .needs, 102_15),
            .expense("Holiday booking", day: 5, .wants, 240_00),
            .expense("Supermarket", day: 9, .needs, 88_60),
            .expense("Restaurant", day: 12, .wants, 67_80),
            .expense("Pharmacy", day: 14, .needs, 21_40),
            .expense("Supermarket", day: 17, .needs, 95_05),
            .expense("Electricity", day: 20, .needs, 49_70),
            .expense("Restaurant", day: 22, .wants, 71_20),
            .expense("Supermarket", day: 24, .needs, 81_30),
            .expense("Birthday gift", day: 26, .wants, 45_00),
            .expense("Car repair", day: 27, .needs, 180_00)
        ],
        [
            .expense("Supermarket", day: 2, .needs, 87_45),
            .expense("Summer sale", day: 6, .wants, 149_90),
            .expense("Supermarket", day: 9, .needs, 79_10),
            .expense("Restaurant", day: 13, .wants, 54_00),
            .expense("Train ticket", day: 14, .needs, 29_50),
            .expense("Supermarket", day: 16, .needs, 90_25),
            .expense("Electricity", day: 20, .needs, 44_80),
            .expense("Cinema", day: 21, .wants, 19_00),
            .expense("Supermarket", day: 23, .needs, 83_60),
            .expense("Restaurant", day: 27, .wants, 62_40)
        ]
    ]

    static func startDate(monthsAgo: Int) -> Date {
        let calendar = Calendar.current
        let currentMonthStart = calendar.dateInterval(of: .month, for: .now)!.start
        return calendar.date(byAdding: .month, value: -monthsAgo, to: currentMonthStart)!
    }

    static func date(day: Int, inMonthStartingAt monthStart: Date) -> Date {
        let calendar = Calendar.current
        let dayStart = calendar.date(byAdding: .day, value: day - 1, to: monthStart)!
        return calendar.date(bySettingHour: 12, minute: 0, second: 0, of: dayStart)!
    }

    static func transactions(monthsAgo: Int) -> [SampleTransaction] {
        let all = recurring + oneOffsByMonthsAgo[monthsAgo]
        guard monthsAgo == 0 else { return all }

        let monthStart = startDate(monthsAgo: monthsAgo)
        return all.filter { date(day: $0.day, inMonthStartingAt: monthStart) <= .now }
    }

    static func group(from transaction: SampleTransaction, in month: Month) -> TransactionGroup {
        let isIncome = transaction.entries.values.contains { $0 > 0 }
        let group = TransactionGroup(
            title: transaction.title,
            type: isIncome ? .income : .expense,
            month: month,
            note: transaction.note,
            imageAttachmentData: nil,
            addedDate: date(day: transaction.day, inMonthStartingAt: month.startDate)
        )
        group.entries = BudgetCategory.allCases.compactMap { category in
            transaction.entries[category].map {
                TransactionEntry(amountCents: $0, category: category, group: group)
            }
        }
        return group
    }
}

extension Month {
    static func sample(monthsAgo: Int) -> Month {
        let month = Month(
            startDate: SampleData.startDate(monthsAgo: monthsAgo),
            currency: Currencies.currency(for: SampleData.currencyCode)!,
            idealBudgetCents: SampleData.idealBudgetCents,
            idealRepartition: SampleData.idealRepartition
        )
        month.transactionGroups = SampleData.transactions(monthsAgo: monthsAgo).map {
            SampleData.group(from: $0, in: month)
        }
        return month
    }

    static let month1 = Month.sample(monthsAgo: 0)
    static let month2 = Month.sample(monthsAgo: 1)
    static let month3 = Month.sample(monthsAgo: 2)
    static let month4 = Month.sample(monthsAgo: 3)

    static let sampleData: [Month] = [month1, month2, month3, month4]

    static func getSampleMonthWithTransactions() -> Month {
        sample(monthsAgo: 1)
    }
}

extension RecurringTransactionRule {
    static let sampleData: [RecurringTransactionRule] = SampleData.recurring.map { transaction in
        let rule = RecurringTransactionRule(
            title: transaction.title,
            frequency: .monthly,
            startDate: SampleData.date(
                day: transaction.day,
                inMonthStartingAt: SampleData.startDate(monthsAgo: SampleData.monthCount - 1)
            ),
            repartition: transaction.entries
        )
        rule.autoConfirm = true
        return rule
    }
}
