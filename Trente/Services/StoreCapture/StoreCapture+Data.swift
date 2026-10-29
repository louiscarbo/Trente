//
//  StoreCapture+Data.swift
//  Trente
//

#if DEBUG
import Foundation

extension StoreCapture {
    static let idealBudgetCents = 4600_00
    static let idealRepartition: [BudgetCategory: Int] = [
        .needs: 2300_00,
        .wants: 1380_00,
        .savingsAndDebts: 920_00
    ]

    static let recurring: [SampleTransaction] = [
        SampleTransaction(
            title: "Paycheck",
            day: 1,
            entries: [
                .needs: 2300_00,
                .wants: 1380_00,
                .savingsAndDebts: 920_00
            ],
            note: "Direct deposit"
        ),
        .expense("Rent", day: 1, .needs, 1250_00),
        .expense("Roth IRA", day: 2, .savingsAndDebts, 300_00),
        .expense("Verizon", day: 5, .needs, 65_00),
        .expense("Student Loan", day: 8, .savingsAndDebts, 220_00),
        .expense("Spotify", day: 12, .wants, 11_99),
        .expense("GEICO", day: 29, .needs, 112_00),
        .expense("Netflix", day: 30, .wants, 15_49)
    ]

    static let oneOffsByMonthsAgo: [[SampleTransaction]] = [
        [
            .expense("Trader Joe's", day: 3, .needs, 72_18),
            .expense("Chipotle", day: 4, .wants, 14_35),
            .expense("Shell", day: 6, .needs, 41_20),
            .expense("Trader Joe's", day: 9, .needs, 58_64),
            .expense("Amazon", day: 10, .wants, 32_99),
            .expense("Olive Garden", day: 11, .wants, 58_40),
            .expense("CVS Pharmacy", day: 13, .needs, 18_47),
            .expense("Sweetgreen", day: 14, .wants, 16_85),
            .expense("Whole Foods", day: 16, .needs, 84_30),
            .expense("Nike", day: 17, .wants, 89_99),
            .expense("AMC Theatres", day: 18, .wants, 28_00),
            .expense("Con Edison", day: 20, .needs, 86_12),
            .expense("Uber", day: 21, .wants, 23_40),
            .expense("Ticketmaster", day: 22, .wants, 120_00),
            .expense("Target", day: 23, .needs, 38_17),
            .expense("Ally Savings", day: 24, .savingsAndDebts, 150_00),
            .expense("Trader Joe's", day: 25, .needs, 64_82),
            .expense("Starbucks", day: 26, .wants, 6_45)
        ],
        [
            .expense("Trader Joe's", day: 4, .needs, 91_60),
            .expense("Olive Garden", day: 6, .wants, 52_30),
            .expense("Whole Foods", day: 11, .needs, 85_75),
            .expense("CVS Pharmacy", day: 13, .needs, 12_90),
            .expense("Ticketmaster", day: 14, .wants, 78_00),
            .expense("Trader Joe's", day: 18, .needs, 96_40),
            .expense("Con Edison", day: 20, .needs, 61_20),
            .expense("Uniqlo", day: 22, .wants, 129_99),
            .expense("Shell", day: 23, .needs, 41_00),
            .expense("Target", day: 25, .needs, 73_85),
            .expense("Chipotle", day: 27, .wants, 38_50)
        ],
        [
            .expense("Trader Joe's", day: 3, .needs, 102_15),
            .expense("Delta Air Lines", day: 5, .wants, 240_00),
            .expense("Whole Foods", day: 9, .needs, 88_60),
            .expense("Olive Garden", day: 12, .wants, 67_80),
            .expense("CVS Pharmacy", day: 14, .needs, 21_40),
            .expense("Trader Joe's", day: 17, .needs, 95_05),
            .expense("Con Edison", day: 20, .needs, 49_70),
            .expense("Sweetgreen", day: 22, .wants, 71_20),
            .expense("Target", day: 24, .needs, 81_30),
            .expense("Amazon", day: 26, .wants, 45_00),
            .expense("Jiffy Lube", day: 27, .needs, 180_00)
        ],
        [
            .expense("Trader Joe's", day: 2, .needs, 87_45),
            .expense("Nike", day: 6, .wants, 149_90),
            .expense("Whole Foods", day: 9, .needs, 79_10),
            .expense("Chipotle", day: 13, .wants, 54_00),
            .expense("Shell", day: 14, .needs, 29_50),
            .expense("Trader Joe's", day: 16, .needs, 90_25),
            .expense("Con Edison", day: 20, .needs, 44_80),
            .expense("AMC Theatres", day: 21, .wants, 19_00),
            .expense("Target", day: 23, .needs, 83_60),
            .expense("Olive Garden", day: 27, .wants, 62_40)
        ]
    ]
}
#endif
