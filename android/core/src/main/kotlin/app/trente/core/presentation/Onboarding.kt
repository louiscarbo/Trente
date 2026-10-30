package app.trente.core.presentation

import app.trente.core.model.BudgetCategory
import app.trente.core.model.Currencies
import app.trente.core.model.Currency
import app.trente.core.model.Month
import app.trente.core.model.RecurrenceFrequency
import app.trente.core.model.RecurringTransactionOccurrence
import app.trente.core.model.RecurringTransactionRule
import app.trente.core.model.TrenteCalendar
import app.trente.core.model.TrenteStore
import app.trente.core.services.MonthService
import app.trente.core.services.RecurringTransactionService
import app.trente.core.support.localized
import java.time.Instant
import java.util.Locale

enum class OnboardingStep { WELCOME, BUDGET, SPLIT, NOTIFICATIONS, ALL_SET }

enum class OnboardingDirection { FORWARD, BACKWARD }

object OnboardingGate {
    const val COMPLETED_KEY = "hasCompletedOnboarding"

    fun shouldShow(hasCompletedOnboarding: Boolean, monthCount: Int, isForced: Boolean): Boolean =
        isForced || (!hasCompletedOnboarding && monthCount == 0)
}

data class MonthDraft(
    var startDate: Instant,
    var currency: Currency,
    var idealBudgetCents: Int,
    var idealRepartition: Map<BudgetCategory, Int>
) {
    fun apply(month: Month) {
        month.startDate = startDate
        month.currency = currency
        month.idealBudgetCents = idealBudgetCents
        month.idealRepartition = idealRepartition
        month.modifiedDate = Instant.now()
    }

    fun makeMonth(): Month = Month(
        startDate = startDate,
        currency = currency,
        idealBudgetCents = idealBudgetCents,
        idealRepartition = idealRepartition
    )

    companion object {
        fun from(month: Month) = MonthDraft(month.startDate, month.currency, month.idealBudgetCents, month.idealRepartition)
    }
}

class OnboardingModel(
    val steps: List<OnboardingStep>,
    locale: Locale = Locale.getDefault(),
    startDate: Instant = Instant.now(),
    private val calendar: TrenteCalendar = TrenteCalendar.current
) {
    var currentStep: OnboardingStep = steps.firstOrNull() ?: OnboardingStep.WELCOME
        private set
    var direction: OnboardingDirection = OnboardingDirection.FORWARD
        private set
    var savedMonth: Month? = null
        private set
    var hasAddedIncome: Boolean = false
        private set
    var draft: MonthDraft = defaultDraft(locale, startDate)
    var isRepartitionComplete: Boolean = false

    val canGoBack: Boolean get() = currentIndex > 0

    val isLastStep: Boolean get() = currentIndex == steps.size - 1

    val canContinue: Boolean
        get() = when (currentStep) {
            OnboardingStep.BUDGET -> draft.idealBudgetCents > 0
            OnboardingStep.SPLIT -> isRepartitionComplete
            OnboardingStep.WELCOME, OnboardingStep.NOTIFICATIONS, OnboardingStep.ALL_SET -> true
        }

    /** Changing the budget re-applies 50/30/20 while the split is untouched, or no longer fits. */
    var budgetCents: Int
        get() = draft.idealBudgetCents
        set(value) {
            val isSplitUntouched = draft.idealRepartition == suggestedRepartition(draft.idealBudgetCents)
            val allocatedCents = draft.idealRepartition.values.sum()
            draft.idealBudgetCents = value
            if (isSplitUntouched || allocatedCents > value) {
                draft.idealRepartition = suggestedRepartition(value)
            }
        }

    fun goForward() {
        if (isLastStep) return
        direction = OnboardingDirection.FORWARD
        currentStep = steps[currentIndex + 1]
    }

    fun goBack() {
        if (!canGoBack) return
        direction = OnboardingDirection.BACKWARD
        currentStep = steps[currentIndex - 1]
    }

    /** Saving twice updates the same month. On first launch, `reusingExistingMonth` adopts a month another screen saved. */
    fun saveMonth(store: TrenteStore, reusingExistingMonth: Boolean = false) {
        if (savedMonth == null && reusingExistingMonth) {
            savedMonth = MonthService.latestMonth(store)
        }
        val existing = savedMonth
        if (existing != null) {
            draft.apply(existing)
            store.save()
        } else {
            val month = draft.makeMonth()
            MonthService.create(month, store)
            savedMonth = month
        }
    }

    /** Logs this month's income and repeats it from next month, not automatically. */
    fun addIncome(store: TrenteStore, now: Instant = Instant.now()) {
        if (hasAddedIncome) return
        val month = savedMonth ?: return
        val repartition = month.idealRepartition.filterValues { it > 0 }
        if (repartition.isEmpty()) return

        val monthStartDate = month.dateInterval(calendar).start
        val rule = RecurringTransactionRule(
            title = localized("Income"),
            frequency = RecurrenceFrequency.MONTHLY,
            startDate = incomeStartDate(monthStartDate, now, calendar),
            repartition = repartition,
            createdAt = now
        )
        store.insert(rule)
        RecurringTransactionService.insertTransaction(
            RecurringTransactionOccurrence(rule, monthStartDate, month),
            store,
            addedDate = monthStartDate,
            calendar = calendar
        )
        store.save()
        hasAddedIncome = true
    }

    private val currentIndex: Int get() = steps.indexOf(currentStep).coerceAtLeast(0)

    companion object {
        val suggestedPercentages: Map<BudgetCategory, Int> =
            mapOf(BudgetCategory.NEEDS to 50, BudgetCategory.WANTS to 30, BudgetCategory.SAVINGS_AND_DEBTS to 20)

        /** The first month start that isn't in the past. */
        fun incomeStartDate(monthStartDate: Instant, today: Instant, calendar: TrenteCalendar = TrenteCalendar.current): Instant {
            val earliestDate = calendar.startOfDay(today)
            var startDate = calendar.startOfDay(monthStartDate)
            do {
                startDate = calendar.plusMonths(startDate, 1)
            } while (startDate < earliestDate)
            return startDate
        }

        fun defaultDraft(locale: Locale, startDate: Instant) = MonthDraft(
            startDate = startDate,
            currency = defaultCurrency(locale),
            idealBudgetCents = 0,
            idealRepartition = suggestedRepartition(0)
        )

        fun defaultCurrency(locale: Locale): Currency {
            val code = try {
                java.util.Currency.getInstance(locale)?.currencyCode
            } catch (exception: IllegalArgumentException) {
                null
            }
            return code?.let(Currencies::currency) ?: Currencies.currency("EUR")!!
        }

        /** Rounds needs and wants down to whole units and gives savings the rest. */
        fun suggestedRepartition(budgetCents: Int): Map<BudgetCategory, Int> {
            val needsCents = roundedDownToWholeUnits(budgetCents * suggestedPercentages.getValue(BudgetCategory.NEEDS) / 100)
            val wantsCents = roundedDownToWholeUnits(budgetCents * suggestedPercentages.getValue(BudgetCategory.WANTS) / 100)
            return mapOf(
                BudgetCategory.NEEDS to needsCents,
                BudgetCategory.WANTS to wantsCents,
                BudgetCategory.SAVINGS_AND_DEBTS to budgetCents - needsCents - wantsCents
            )
        }

        private fun roundedDownToWholeUnits(cents: Int): Int = (cents / 100) * 100
    }
}
