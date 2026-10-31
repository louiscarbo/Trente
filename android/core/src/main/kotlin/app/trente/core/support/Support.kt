package app.trente.core.support

import java.util.Locale

object ExternalLinks {
    const val writeReview = "https://play.google.com/store/apps/details?id=app.trente"
    const val manageSubscriptions = "https://play.google.com/store/account/subscriptions"
    const val ccBy3License = "https://creativecommons.org/licenses/by/3.0/"
    const val piggySavingsIcon = "https://thenounproject.com/icon/piggy-savings-5860187/"
    const val financialStartupIcon = "https://thenounproject.com/icon/financial-startup-5860236/"
    const val developerWebsite = "https://carbo-estaque.fr"
    const val termsOfUse = "https://play.google.com/about/play-terms/"
    const val developerLinkedIn = "https://www.linkedin.com/in/louis-carbo-estaque/"
    const val developerGitHub = "https://github.com/louiscarbo"

    private val privacyPolicyPages = mapOf(
        "en" to "privacy/",
        "en-GB" to "en-gb/privacy/",
        "de" to "de/datenschutz/",
        "es" to "es/privacidad/",
        "es-419" to "es-419/privacidad/",
        "fr" to "fr/confidentialite/",
        "it" to "it/privacy/",
        "ko" to "ko/privacy/",
        "pt-BR" to "pt-br/privacidade/",
        "pt-PT" to "pt-pt/privacidade/"
    )

    val privacyPolicy: String get() = privacyPolicy(Locale.getDefault())

    fun privacyPolicy(locale: Locale): String {
        val page = privacyPolicyPages[locale.toLanguageTag()] ?: privacyPolicyPages[locale.language] ?: "privacy/"
        return "https://trente.app/$page"
    }
}

data class AppInfo(
    val version: String,
    val build: String,
    val systemName: String,
    val systemVersion: String
) {
    val versionDescription: String get() = "$version ($build)"

    val systemDescription: String get() = "$systemName $systemVersion"

    companion object {
        fun formattedSystemVersion(major: Int, minor: Int, patch: Int): String {
            val components = listOf(major, minor) + if (patch == 0) emptyList() else listOf(patch)
            return components.joinToString(".")
        }
    }
}

object SupportMail {
    const val ADDRESS = "louis@trente.app"

    // `urlQueryAllowed` minus the characters with a meaning inside a query.
    private const val ALLOWED = "!$'()*,-./:;@_~"

    fun url(to: String, subject: String, body: String): String? =
        "mailto:$to?subject=${percentEncoded(subject)}&body=${percentEncoded(body)}"

    fun feedbackBody(appInfo: AppInfo): String = "\n\n\n—\nTrente ${appInfo.versionDescription} · ${appInfo.systemDescription}"

    fun feedbackURL(appInfo: AppInfo): String? = url(ADDRESS, localized("Trente Feedback"), feedbackBody(appInfo))

    private fun percentEncoded(text: String): String {
        val output = StringBuilder()
        for (byte in text.toByteArray(Charsets.UTF_8)) {
            val character = byte.toInt().toChar()
            if (byte >= 0 && (character.isLetterOrDigit() || ALLOWED.indexOf(character) >= 0)) {
                output.append(character)
            } else {
                output.append('%').append(String.format("%02X", byte.toInt() and 0xFF))
            }
        }
        return output.toString()
    }
}

enum class FAQTopic(val title: String) {
    BUDGET_BASICS("Budget Basics"),
    RECURRING("Recurring Transactions"),
    FEATURES_AND_DATA("Features and Data")
}

data class FAQSection(val topic: FAQTopic, val items: List<FAQItem>) {
    companion object {
        fun sections(items: List<FAQItem>): List<FAQSection> = FAQTopic.entries.mapNotNull { topic ->
            val topicItems = items.filter { it.topic == topic }
            if (topicItems.isEmpty()) null else FAQSection(topic, topicItems)
        }
    }
}

/** `question` and `answer` are English keys for `localized()`. */
data class FAQItem(
    val id: String,
    val topic: FAQTopic,
    val question: String,
    val answer: String
) {
    companion object {
        val featured = FAQItem(
            id = "fiftyThirtyTwenty",
            topic = FAQTopic.BUDGET_BASICS,
            question = "What is the 50/30/20 rule?",
            answer = "A simple way to split your take-home income: about 50% for needs (rent, groceries, bills), " +
                "30% for wants (dining out, fun) and 20% for savings and paying off debt. " +
                "Trente sorts every transaction into one of these three categories. You can choose your own split for each month."
        )

        val all: List<FAQItem> = listOf(
            featured,
            FAQItem(
                id = "months",
                topic = FAQTopic.BUDGET_BASICS,
                question = "How do months work in Trente?",
                answer = "A month starts on the date of your choice and lasts one month, " +
                    "for example from October 25 to November 24, to match your payday."
            ),
            FAQItem(
                id = "remaining",
                topic = FAQTopic.BUDGET_BASICS,
                question = "Why doesn't my month show any amount left?",
                answer = "The amount left is the income you've logged this month, minus your expenses.\n" +
                    "If your month shows no amount left, start by adding an income: tap “New Transaction”."
            ),
            FAQItem(
                id = "splitIncome",
                topic = FAQTopic.BUDGET_BASICS,
                question = "How do I split an income across categories?",
                answer = "When you add an income, choose how much goes to Needs, Wants and Savings and Debts. " +
                    "An expense always goes into a single category."
            ),
            FAQItem(
                id = "recurring",
                topic = FAQTopic.RECURRING,
                question = "What are recurring transactions?",
                answer = "Transactions that come back every week, month or year, like rent or a salary.\n" +
                    "Trente reminds you to confirm the transaction on the day it's due.\n" +
                    "Trente+ subscribers can turn on automatic confirmation for recurring transactions."
            ),
            FAQItem(
                id = "automatic",
                topic = FAQTopic.RECURRING,
                question = "What does the “Automatic” option do?",
                answer = "Trente+ subscribers can turn on automatic confirmation for recurring transactions. " +
                    "You then no longer need to open Trente to add the transaction to your budget. " +
                    "It's handy for regular transactions you can count on, like a salary."
            ),
            FAQItem(
                id = "data",
                topic = FAQTopic.FEATURES_AND_DATA,
                question = "Where is my data stored?",
                answer = "Your data belongs to you, and Trente never has access to it.\n" +
                    "It's stored on your device only.\n" +
                    "Trente has no account and no server, and never connects to your bank.\n" +
                    "To delete your data, delete the app."
            ),
            FAQItem(
                id = "trentePlus",
                topic = FAQTopic.FEATURES_AND_DATA,
                question = "What is Trente+?",
                answer = "An optional monthly or yearly subscription that unlocks new features in Trente. " +
                    "Open Trente's Settings to learn more.\n" +
                    "Trente+ is also a way to support me as an independent developer.\n" +
                    "Manage or cancel your subscription anytime from Google Play."
            ),
            FAQItem(
                id = "widgets",
                topic = FAQTopic.FEATURES_AND_DATA,
                question = "How do I change the category shown in the “Category Recap” widget?",
                answer = "Touch and hold the widget, then tap the settings button. You can then change the widget's category."
            )
        )

        fun matching(query: String, items: List<FAQItem>): List<FAQItem> {
            val words = query.split(Regex("\\s+")).filter { it.isNotEmpty() }
            if (words.isEmpty()) return items
            return items.filter { item ->
                val text = localized(item.question) + " " + localized(item.answer)
                words.all { word -> TextSearch.contains(text, word) }
            }
        }
    }
}
