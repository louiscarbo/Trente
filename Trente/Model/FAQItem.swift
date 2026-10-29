//
//  FAQItem.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 24/10/2026.
//

import Foundation

enum FAQTopic: CaseIterable {
    case budgetBasics
    case recurring
    case featuresAndData

    var title: LocalizedStringResource {
        switch self {
        case .budgetBasics:
            "Budget Basics"
        case .recurring:
            "Recurring Transactions"
        case .featuresAndData:
            "Features and Data"
        }
    }
}

struct FAQSection: Identifiable, Equatable {
    let topic: FAQTopic
    let items: [FAQItem]

    var id: FAQTopic { topic }
}

struct FAQItem: Identifiable, Equatable {
    let id: String
    let topic: FAQTopic
    let question: LocalizedStringResource
    let answer: LocalizedStringResource
    var isPhoneOnly = false

    static func == (lhs: FAQItem, rhs: FAQItem) -> Bool {
        lhs.id == rhs.id
    }

    static let featured = FAQItem(
        id: "fiftyThirtyTwenty",
        topic: .budgetBasics,
        question: "What is the 50/30/20 rule?",
        answer: """
            A simple way to split your take-home income: about 50% for Needs (rent, groceries, bills), \
            30% for Wants (dining out, entertainment) and 20% for Savings and Debts. \
            Trente sorts every transaction into these three categories. You can choose your own split for each month.
            """
    )

    static let all: [FAQItem] = [
        featured,
        FAQItem(
            id: "months",
            topic: .budgetBasics,
            question: "How do months work in Trente?",
            answer: """
                A month starts on the date you choose and lasts one month, for example October 25 to November 24, \
                so you can line it up with your payday. A new month keeps your currency and ideal budget.
                """
        ),
        FAQItem(
            id: "remaining",
            topic: .budgetBasics,
            question: "Why does my month show nothing remaining?",
            answer: """
                “Remaining” is the income you logged this month minus what you spent. Your ideal budget is only a target. \
                Add your paycheck as an income and your remaining amounts appear, overall and per category.
                """
        ),
        FAQItem(
            id: "splitIncome",
            topic: .budgetBasics,
            question: "How do I split an income between categories?",
            answer: """
                When you add an income, choose how much goes to Needs, Wants and Savings and Debts. \
                An expense always goes to a single category.
                """
        ),
        FAQItem(
            id: "recurring",
            topic: .recurring,
            question: "What are recurring transactions?",
            answer: """
                Transactions that come back every week, month or year, like rent or a salary. \
                Upcoming ones appear in the months you've created. Open one to mark it as Paid (or Received) \
                or to skip just that one. A recurring transaction never changes past months.
                """
        ),
        FAQItem(
            id: "automatic",
            topic: .recurring,
            question: "What does “automatic” do?",
            answer: """
                With Trente+, Trente adds it for you on its due date, the next time you open the app. \
                Your widgets count it right away. Without Trente+, the setting is kept but you confirm it yourself.
                """
        ),
        FAQItem(
            id: "applePay",
            topic: .featuresAndData,
            question: "Can Trente log my Apple Pay purchases?",
            answer: """
                Yes. Get the Trente shortcut from Settings. Then, in Shortcuts › Automation, create an automation \
                with the Wallet trigger, choose your cards and select Run Immediately. Add Run Shortcut, \
                pick Log Wallet Transaction and pass it the Shortcut Input. After each purchase, tap the notification, \
                check the category and save. Nothing is added without your validation. \
                Free for 10 purchases a month, unlimited with Trente+.
                """,
            isPhoneOnly: true
        ),
        FAQItem(
            id: "data",
            topic: .featuresAndData,
            question: "Where is my data stored?",
            answer: """
                On your devices and in your own iCloud account, which keeps them in sync when they use the same \
                Apple Account. Without iCloud, it stays on this device and in its backups. Trente has no account \
                and no server, and never connects to your bank. Deleting the app leaves your data in iCloud.
                """
        ),
        FAQItem(
            id: "trentePlus",
            topic: .featuresAndData,
            question: "What is Trente+?",
            answer: """
                An optional monthly or yearly subscription that adds your recurring transactions automatically \
                and lets you attach notes and images to any transaction. On iPhone and iPad, you can change \
                the app icon's color too. On iPhone, you can log unlimited Apple Pay purchases. \
                It also supports an independent developer. \
                Manage or cancel it anytime in your App Store account.
                """
        ),
        FAQItem(
            id: "widgets",
            topic: .featuresAndData,
            question: "Which widgets are available?",
            answer: """
                Month Recap (remaining budget and spending) and Category Recap (what's left in one category; \
                edit the widget to choose it). Both are also available on the Lock Screen on iPhone.
                """
        )
    ]
}
