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
            A simple way to split your take-home income: about 50% for needs (rent, groceries, bills), \
            30% for wants (dining out, fun) and 20% for savings and paying off debt. \
            Trente sorts every transaction into one of these three categories. You can choose your own split for each month.
            """
    )

    static let all: [FAQItem] = [
        featured,
        FAQItem(
            id: "months",
            topic: .budgetBasics,
            question: "How do months work in Trente?",
            answer: """
                A month starts on the date of your choice and lasts one month, \
                for example from October 25 to November 24, to match your payday.
                """
        ),
        FAQItem(
            id: "remaining",
            topic: .budgetBasics,
            question: "Why doesn't my month show any amount left?",
            answer: """
                The amount left is the income you've logged this month, minus your expenses.
                If your month shows no amount left, start by adding an income: tap “New Transaction”.
                """
        ),
        FAQItem(
            id: "splitIncome",
            topic: .budgetBasics,
            question: "How do I split an income across categories?",
            answer: """
                When you add an income, choose how much goes to Needs, Wants and Savings and Debts. \
                An expense always goes into a single category.
                """
        ),
        FAQItem(
            id: "recurring",
            topic: .recurring,
            question: "What are recurring transactions?",
            answer: """
                Transactions that come back every week, month or year, like rent or a salary.
                Trente reminds you to confirm the transaction on the day it's due.
                Trente+ subscribers can turn on automatic confirmation for recurring transactions.
                """
        ),
        FAQItem(
            id: "automatic",
            topic: .recurring,
            question: "What does the “Automatic” option do?",
            answer: """
                Trente+ subscribers can turn on automatic confirmation for recurring transactions. \
                You then no longer need to open Trente to add the transaction to your budget. \
                It's handy for regular transactions you can count on, like a salary.
                """
        ),
        FAQItem(
            id: "applePay",
            topic: .featuresAndData,
            question: "Can Trente log my Apple Pay purchases?",
            answer: """
                Yes. From Trente's Settings, you can add the shortcut that connects Trente to Apple Pay. \
                Follow the instructions in Trente's Settings.
                After each purchase, tap the notification, add the category and save. \
                No transaction is added without your confirmation.
                Without a subscription, Apple Pay logging is limited to 10 expenses a month. \
                Trente+ subscribers can add as many transactions as they like.
                """,
            isPhoneOnly: true
        ),
        FAQItem(
            id: "data",
            topic: .featuresAndData,
            question: "Where is my data stored?",
            answer: """
                Your data belongs to you, and Trente never has access to it.
                It's stored on your devices, and in your iCloud account if you turn on iCloud for Trente.
                Trente has no account and no server, and never connects to your bank.
                To delete your data, turn off iCloud sync for Trente in your device's Settings, then delete the app.
                """
        ),
        FAQItem(
            id: "trentePlus",
            topic: .featuresAndData,
            question: "What is Trente+?",
            answer: """
                An optional monthly or yearly subscription that unlocks new features in Trente. \
                Open Trente's Settings to learn more.
                Trente+ is also a way to support me as an independent developer.
                Manage or cancel your subscription anytime from your Apple Account.
                """
        ),
        FAQItem(
            id: "widgets",
            topic: .featuresAndData,
            question: "How do I change the category shown in the “Category Recap” widget?",
            answer: """
                Touch and hold the widget, then tap “Edit Widget”. You can then change the widget's category.
                """
        )
    ]
}
