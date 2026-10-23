//
//  FAQItem.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 24/10/2026.
//

import Foundation

struct FAQItem: Identifiable, Equatable {
    let id: String
    let question: LocalizedStringResource
    let answer: LocalizedStringResource
    var isPhoneOnly = false

    static func items(isPhone: Bool) -> [FAQItem] {
        isPhone ? all : all.filter { item in !item.isPhoneOnly }
    }

    static let all: [FAQItem] = [
        FAQItem(
            id: "fiftyThirtyTwenty",
            question: "What is the 50/30/20 rule?",
            answer: """
                A simple way to split your take-home income: about 50% for Needs (rent, groceries, bills), \
                30% for Wants (dining out, entertainment) and 20% for Savings and Debts. \
                Trente sorts every transaction into these three categories. You can choose your own split for each month.
                """
        ),
        FAQItem(
            id: "months",
            question: "How do months work in Trente?",
            answer: """
                A month starts on the date you choose and lasts one month, for example October 25 to November 24, \
                so you can line it up with your payday. A new month keeps your currency and ideal budget.
                """
        ),
        FAQItem(
            id: "remaining",
            question: "Why does my month show nothing remaining?",
            answer: """
                “Remaining” is the income you logged this month minus what you spent. Your ideal budget is only a target. \
                Add your paycheck as an income and your remaining amounts appear, overall and per category.
                """
        ),
        FAQItem(
            id: "splitIncome",
            question: "How do I split an income between categories?",
            answer: """
                When you add an income, choose how much goes to Needs, Wants and Savings and Debts. \
                An expense always goes to a single category.
                """
        ),
        FAQItem(
            id: "recurring",
            question: "What are recurring transactions?",
            answer: """
                Transactions that come back every week, month or year, like rent or a salary. \
                Upcoming ones appear in the months you've created. Tap one, or swipe it, to mark it as Paid (or Received) \
                or to skip just that one. A recurring transaction never changes past months.
                """
        ),
        FAQItem(
            id: "automatic",
            question: "What does “automatic” do?",
            answer: """
                Trente adds it for you on its due date, the next time you open the app. Your widgets count it right away.
                """
        ),
        FAQItem(
            id: "applePay",
            question: "Can Trente log my Apple Pay purchases?",
            answer: """
                Yes. Get the Trente shortcut from Settings. Then, in Shortcuts › Automation, create an automation \
                with the Wallet trigger, choose your cards and select Run Immediately. Add Run Shortcut, \
                pick Log Wallet Transaction and pass it the Shortcut Input. After each purchase, tap the notification, \
                check the category and save. Nothing is added without your validation.
                """,
            isPhoneOnly: true
        ),
        FAQItem(
            id: "data",
            question: "Where is my data stored?",
            answer: """
                Only on this device. Trente has no account and never connects to your bank. \
                Deleting the app deletes your data.
                """
        ),
        FAQItem(
            id: "trentePlus",
            question: "What is Trente+?",
            answer: """
                An optional monthly or yearly subscription that lets you attach notes and images to your transactions, \
                and supports an independent developer. Manage or cancel it anytime in your App Store account.
                """
        ),
        FAQItem(
            id: "widgets",
            question: "Which widgets are available?",
            answer: """
                Month Recap (remaining budget and spending) and Category Recap (what's left in one category; \
                touch and hold the widget to choose it). Both are also available on the Lock Screen on iPhone.
                """
        )
    ]
}
