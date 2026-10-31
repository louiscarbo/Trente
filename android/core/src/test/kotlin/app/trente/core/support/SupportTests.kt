package app.trente.core.support

import app.trente.core.EUR
import app.trente.core.FakeNotificationCenter
import app.trente.core.model.Currencies
import app.trente.core.model.Month
import app.trente.core.model.TrenteCalendar
import app.trente.core.model.TrentePlusBenefit
import app.trente.core.services.DeepLink
import app.trente.core.services.ReviewRequestPolicy
import app.trente.core.services.TrentePlus
import app.trente.core.services.TrentePlusDebugOverride
import app.trente.core.services.SubscriptionState
import java.time.Instant
import java.util.Currency
import java.util.Locale
import java.util.UUID
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

class ReviewRequestPolicyTests {
    private val calendar = TrenteCalendar.current

    private fun day(year: Int, month: Int, day: Int, hour: Int = 12) = calendar.date(year, month, day, hour)

    @Test
    fun monthsAndDaysOfUse() {
        for ((monthCount, daysOfUse, expected) in listOf(
            Triple(0, 30, false), Triple(1, 30, false), Triple(2, 30, true),
            Triple(2, 13, false), Triple(2, 14, true), Triple(5, 60, true)
        )) {
            val firstUse = day(2026, 1, 1)
            val now = calendar.plusDays(firstUse, daysOfUse.toLong())

            val shouldRequest = ReviewRequestPolicy.shouldRequest(
                monthCount = monthCount,
                lastRequestedMonthCount = 0,
                lastRequestedVersion = "",
                currentVersion = "1.0",
                firstUseDate = firstUse,
                now = now,
                calendar = calendar
            )

            assertEquals(expected, shouldRequest, "$monthCount months, $daysOfUse days")
        }
    }

    @Test
    fun missingFirstUse() {
        assertFalse(
            ReviewRequestPolicy.shouldRequest(
                monthCount = 3, lastRequestedMonthCount = 0, lastRequestedVersion = "", currentVersion = "1.0",
                firstUseDate = null, now = day(2026, 6, 1), calendar = calendar
            )
        )
    }

    @Test
    fun versionAndMonthCount() {
        data class Case(val lastCount: Int, val lastVersion: String, val monthCount: Int, val version: String, val expected: Boolean)
        for (case in listOf(
            Case(2, "1.0", 2, "1.0", false), Case(2, "1.0", 3, "1.0", false), Case(2, "1.0", 2, "1.1", false),
            Case(2, "1.0", 3, "1.1", true), Case(0, "", 2, "1.0", true)
        )) {
            val shouldRequest = ReviewRequestPolicy.shouldRequest(
                monthCount = case.monthCount,
                lastRequestedMonthCount = case.lastCount,
                lastRequestedVersion = case.lastVersion,
                currentVersion = case.version,
                firstUseDate = day(2026, 1, 1),
                now = day(2026, 6, 1),
                calendar = calendar
            )
            assertEquals(case.expected, shouldRequest, "$case")
        }
    }

    @Test
    fun calendarDays() {
        assertTrue(
            ReviewRequestPolicy.shouldRequest(
                monthCount = 2, lastRequestedMonthCount = 0, lastRequestedVersion = "", currentVersion = "1.0",
                firstUseDate = day(2026, 1, 1, hour = 23), now = day(2026, 1, 15, hour = 1), calendar = calendar
            )
        )
    }
}

class FAQItemTests {
    private fun item(id: String, topic: FAQTopic = FAQTopic.BUDGET_BASICS, question: String = "Question", answer: String = "Answer") =
        FAQItem(id, topic, question, answer)

    @Test
    fun uniqueIdentifiers() {
        val identifiers = FAQItem.all.map { it.id }

        assertEquals(identifiers.size, identifiers.toSet().size)
    }

    @Test
    fun nonEmptyText() {
        for (item in FAQItem.all) {
            assertTrue(localized(item.question).isNotEmpty())
            assertTrue(localized(item.answer).isNotEmpty())
        }
    }

    @Test
    fun everyTopicHasQuestions() {
        assertEquals(FAQTopic.entries, FAQSection.sections(FAQItem.all).map { it.topic })
    }

    @Test
    fun featuredIsListed() {
        assertTrue(FAQItem.all.contains(FAQItem.featured))
    }

    @Test
    fun sectionsFollowTopicOrder() {
        val items = listOf(item("rent", FAQTopic.RECURRING), item("months", FAQTopic.BUDGET_BASICS), item("salary", FAQTopic.RECURRING))

        val sections = FAQSection.sections(items)

        assertEquals(listOf(FAQTopic.BUDGET_BASICS, FAQTopic.RECURRING), sections.map { it.topic })
        assertEquals(listOf("rent", "salary"), sections.last().items.map { it.id })
    }

    @Test
    fun emptySearchKeepsEverything() {
        val items = listOf(item("rent"), item("salary"))

        assertEquals(items, FAQItem.matching("   ", items))
    }

    @Test
    fun searchIgnoresCaseAndAccents() {
        val items = listOf(item("cafe", question = "Café budget"), item("rent", question = "Rent"))

        assertEquals(listOf("cafe"), FAQItem.matching("CAFE", items).map { it.id })
    }

    @Test
    fun searchNeedsEveryWord() {
        val items = listOf(item("rent", question = "What is rent?", answer = "Paid monthly"))

        assertEquals(listOf("rent"), FAQItem.matching("rent monthly", items).map { it.id })
        assertTrue(FAQItem.matching("rent yearly", items).isEmpty())
    }
}

class CurrencyDisplayNameTests {
    @Test
    fun displayNamesAreCapitalized() {
        for (currency in Currencies.availableCurrencies) {
            assertTrue(currency.displayName.first().isUpperCase(), "${currency.isoCode}: ${currency.displayName}")
        }
    }

    @Test
    fun displayNameComesFromLocale() {
        val systemName = Currency.getInstance("EUR").getDisplayName(Locale.getDefault())

        assertEquals(systemName.lowercase(), EUR.displayName.lowercase())
    }
}

class DeepLinkTests {
    private val monthID: UUID = UUID.fromString("6F1C2A4E-8B3D-4E5F-9A7B-1C2D3E4F5A6B")

    @Test
    fun parsesLink() {
        val cases = listOf(
            "trente://newtransaction/6F1C2A4E-8B3D-4E5F-9A7B-1C2D3E4F5A6B" to DeepLink.NewTransaction(monthID),
            "trente://month/6F1C2A4E-8B3D-4E5F-9A7B-1C2D3E4F5A6B" to DeepLink.Month(monthID),
            "TRENTE://NewTransaction/6f1c2a4e-8b3d-4e5f-9a7b-1c2d3e4f5a6b" to DeepLink.NewTransaction(monthID),
            "trente://month/6F1C2A4E-8B3D-4E5F-9A7B-1C2D3E4F5A6B/" to DeepLink.Month(monthID)
        )
        for ((text, expected) in cases) {
            assertEquals(expected, DeepLink.parse(text), text)
        }
    }

    @Test
    fun rejectsLink() {
        val links = listOf(
            "https://newtransaction/6F1C2A4E-8B3D-4E5F-9A7B-1C2D3E4F5A6B",
            "trente://newtransaction",
            "trente://newtransaction/not-a-uuid",
            "trente://newtransaction/6F1C2A4E-8B3D-4E5F-9A7B-1C2D3E4F5A6B/extra",
            "trente://unknown/6F1C2A4E-8B3D-4E5F-9A7B-1C2D3E4F5A6B",
            "trente:newtransaction/6F1C2A4E-8B3D-4E5F-9A7B-1C2D3E4F5A6B"
        )
        for (text in links) {
            assertNull(DeepLink.parse(text), text)
        }
    }

    @Test
    fun roundTrip() {
        for (link in listOf(DeepLink.Month(monthID), DeepLink.NewTransaction(monthID))) {
            assertEquals(link, DeepLink.parse(link.url))
        }
    }

    @Test
    fun widgetFormat() {
        assertEquals(DeepLink.NewTransaction(monthID), DeepLink.parse("trente://newtransaction/" + monthID.toString().uppercase()))
    }

    private fun makeMonth(daysAgo: Long) = Month(
        startDate = TrenteCalendar.current.plusDays(Instant.now(), -daysAgo),
        currency = EUR,
        idealBudgetCents = 2000_00,
        idealRepartition = emptyMap()
    )

    @Test
    fun knownMonth() {
        val latest = makeMonth(0)
        val older = makeMonth(40)

        val newTransaction = DeepLink.NewTransaction(older.id).destination(listOf(latest, older))!!
        assertTrue(newTransaction.month === older)
        assertTrue(newTransaction.opensNewTransaction)

        val month = DeepLink.Month(older.id).destination(listOf(latest, older))!!
        assertTrue(month.month === older)
        assertFalse(month.opensNewTransaction)
    }

    @Test
    fun unknownMonth() {
        val latest = makeMonth(0)
        val older = makeMonth(40)

        val destination = DeepLink.NewTransaction(UUID.randomUUID()).destination(listOf(latest, older))!!

        assertTrue(destination.month === latest)
        assertFalse(destination.opensNewTransaction)
    }

    @Test
    fun noMonths() {
        assertNull(DeepLink.NewTransaction(monthID).destination(emptyList()))
    }
}

class TrentePlusTests {
    @Test
    fun isActive() {
        val cases = listOf(
            emptyList<SubscriptionState>() to false,
            listOf(SubscriptionState.EXPIRED) to false,
            listOf(SubscriptionState.REVOKED) to false,
            listOf(SubscriptionState.IN_BILLING_RETRY_PERIOD) to false,
            listOf(SubscriptionState.SUBSCRIBED) to true,
            listOf(SubscriptionState.IN_GRACE_PERIOD) to true,
            listOf(SubscriptionState.EXPIRED, SubscriptionState.IN_GRACE_PERIOD) to true
        )
        for ((states, expected) in cases) {
            assertEquals(expected, TrentePlus.isActive(states), "$states")
        }
    }

    @Test
    fun endDate() {
        val april = Instant.ofEpochSecond(1_743_000_000)
        val may = april.plusSeconds(30 * 86_400)

        assertNull(TrentePlus.endDate(emptyList()))
        assertNull(TrentePlus.endDate(listOf(TrentePlus.Renewal(true, april))))
        assertEquals(april, TrentePlus.endDate(listOf(TrentePlus.Renewal(false, april))))
        assertEquals(may, TrentePlus.endDate(listOf(TrentePlus.Renewal(false, april), TrentePlus.Renewal(false, may))))
        assertNull(TrentePlus.endDate(listOf(TrentePlus.Renewal(false, april), TrentePlus.Renewal(true, may))))
    }

    @Test
    fun debugOverride() {
        val cases = listOf(
            Triple(TrentePlusDebugOverride.STORE, false, false),
            Triple(TrentePlusDebugOverride.STORE, true, true),
            Triple(TrentePlusDebugOverride.SUBSCRIBED, false, true),
            Triple(TrentePlusDebugOverride.NOT_SUBSCRIBED, true, false)
        )
        for ((override, hasActiveSubscription, expected) in cases) {
            assertEquals(expected, override.isSubscribed(hasActiveSubscription))
        }
    }

    @Test
    fun debugOverrideStorage() {
        val defaults = InMemoryKeyValueStore()

        assertEquals(TrentePlusDebugOverride.STORE, TrentePlusDebugOverride.stored(defaults))
        TrentePlusDebugOverride.NOT_SUBSCRIBED.store(defaults)
        assertEquals(TrentePlusDebugOverride.NOT_SUBSCRIBED, TrentePlusDebugOverride.stored(defaults))
    }
}

class TrentePlusBenefitTests {
    @Test
    fun uniqueIdentifiers() {
        val identifiers = TrentePlusBenefit.all.map { it.id }

        assertEquals(identifiers.size, identifiers.toSet().size)
    }

    @Test
    fun order() {
        assertEquals("automaticRecurring", TrentePlusBenefit.all.first().id)
        assertEquals("supportIndieDeveloper", TrentePlusBenefit.all.last().id)
    }

    @Test
    fun nonEmptyText() {
        for (benefit in TrentePlusBenefit.all) {
            assertTrue(localized(benefit.title).isNotEmpty())
            assertTrue(localized(benefit.detail).isNotEmpty())
        }
    }
}

class AppInfoTests {
    private val appInfo = AppInfo(version = "1.0", build = "1", systemName = "Android", systemVersion = "15")

    @Test
    fun versionDescription() {
        assertEquals("1.0 (1)", appInfo.versionDescription)
    }

    @Test
    fun systemDescription() {
        assertEquals("Android 15", appInfo.systemDescription)
    }

    @Test
    fun formattedSystemVersion() {
        assertEquals("27.0", AppInfo.formattedSystemVersion(27, 0, 0))
        assertEquals("27.1", AppInfo.formattedSystemVersion(27, 1, 0))
        assertEquals("27.1.2", AppInfo.formattedSystemVersion(27, 1, 2))
        assertEquals("27.0.1", AppInfo.formattedSystemVersion(27, 0, 1))
    }
}

class SupportMailTests {
    private val appInfo = AppInfo(version = "1.0", build = "1", systemName = "Android", systemVersion = "15")

    @Test
    fun schemeAndAddress() {
        val url = SupportMail.url("hello@example.com", subject = "Hi", body = "Hello")

        assertNotNull(url)
        assertTrue(url.startsWith("mailto:hello@example.com?"))
    }

    @Test
    fun spaces() {
        val url = SupportMail.url("hello@example.com", subject = "Trente Feedback", body = "A B")

        assertEquals("mailto:hello@example.com?subject=Trente%20Feedback&body=A%20B", url)
    }

    @Test
    fun reservedCharacters() {
        for ((character, encoded) in listOf("&" to "%26", "+" to "%2B", "=" to "%3D", "?" to "%3F", "#" to "%23", "\n" to "%0A")) {
            val url = SupportMail.url("hello@example.com", subject = "Subject", body = "a${character}b")

            assertTrue(url!!.endsWith("&body=a${encoded}b"), url)
        }
    }

    @Test
    fun feedbackBody() {
        assertTrue(SupportMail.feedbackBody(appInfo).endsWith("\nTrente 1.0 (1) · Android 15"))
    }

    @Test
    fun feedbackURL() {
        assertTrue(SupportMail.feedbackURL(appInfo)!!.startsWith("mailto:${SupportMail.ADDRESS}?subject="))
    }
}

class ExternalLinksTests {
    @Test
    fun developerWebsite() {
        assertEquals("https://carbo-estaque.fr", ExternalLinks.developerWebsite)
    }

    @Test
    fun privacyPolicyHost() {
        assertTrue(ExternalLinks.privacyPolicy.startsWith("https://trente.app/"))
    }

    @Test
    fun privacyPolicyFollowsTheLanguage() {
        assertEquals("https://trente.app/privacy/", ExternalLinks.privacyPolicy(java.util.Locale.US))
        assertEquals("https://trente.app/en-gb/privacy/", ExternalLinks.privacyPolicy(java.util.Locale.UK))
        assertEquals("https://trente.app/fr/confidentialite/", ExternalLinks.privacyPolicy(java.util.Locale.FRANCE))
        assertEquals("https://trente.app/pt-br/privacidade/", ExternalLinks.privacyPolicy(java.util.Locale.forLanguageTag("pt-BR")))
        assertEquals("https://trente.app/es-419/privacidad/", ExternalLinks.privacyPolicy(java.util.Locale.forLanguageTag("es-419")))
        assertEquals("https://trente.app/privacy/", ExternalLinks.privacyPolicy(java.util.Locale.JAPAN))
    }

    @Test
    fun legalLinksUseHTTPS() {
        for (url in listOf(ExternalLinks.privacyPolicy, ExternalLinks.termsOfUse)) {
            assertTrue(url.startsWith("https://"))
        }
    }
}

class NotificationPermissionServiceTests {
    @Test
    fun status() = runTest {
        for (status in NotificationPermissionStatus.entries) {
            val service = NotificationPermissionService(FakeNotificationCenter(status, grants = true))

            assertEquals(status, service.status())
        }
    }

    @Test
    fun requestWhenNotAsked() = runTest {
        for (grants in listOf(true, false)) {
            val center = FakeNotificationCenter(NotificationPermissionStatus.NOT_DETERMINED, grants)
            val service = NotificationPermissionService(center)

            val status = service.requestIfNeeded()

            assertEquals(if (grants) NotificationPermissionStatus.AUTHORIZED else NotificationPermissionStatus.DENIED, status)
            assertEquals(1, center.requestCount)
        }
    }

    @Test
    fun noRequestWhenAlreadyAnswered() = runTest {
        for (status in listOf(NotificationPermissionStatus.AUTHORIZED, NotificationPermissionStatus.DENIED)) {
            val center = FakeNotificationCenter(status, grants = true)

            NotificationPermissionService(center).requestIfNeeded()

            assertEquals(0, center.requestCount)
        }
    }
}
