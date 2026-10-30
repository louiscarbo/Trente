package app.trente.core.presentation

import app.trente.core.model.BudgetCategory
import app.trente.core.model.Month
import app.trente.core.model.TransactionType
import app.trente.core.model.TrenteCalendar
import java.time.Instant
import kotlin.math.abs
import kotlin.math.max
import kotlin.math.min
import kotlin.math.round
import kotlin.math.roundToInt

/** The two rings of the dashboard: what was spent per category, against how income is split. */
data class BudgetRings(
    val spent: Map<BudgetCategory, Double>,
    val income: Map<BudgetCategory, Double>
) {
    constructor(month: Month) : this(
        spent = BudgetCategory.entries.associateWith { month.spentAmount(it) },
        income = BudgetCategory.entries.associateWith { month.incomeAmount(it) }
    )

    enum class Lens { SPLIT, LEFT_TO_SPEND }

    sealed class SliceKind {
        data class Category(val category: BudgetCategory) : SliceKind()
        data object Remaining : SliceKind()
        data object Overspent : SliceKind()
    }

    data class Slice(val kind: SliceKind, val share: Double) {
        val id: SliceKind get() = kind
    }

    val totalSpent: Double get() = spent.values.sum()

    val totalIncome: Double get() = income.values.sum()

    val hasSpending: Boolean get() = totalSpent > 0

    val isOverspent: Boolean get() = totalSpent > totalIncome

    fun segments(lens: Lens): List<Slice> {
        return when (lens) {
            Lens.SPLIT -> {
                val total = totalSpent
                categorySlices { if (total > 0) (spent[it] ?: 0.0) / total else 0.0 } + leftoverSlices(remaining = 0.0, overspent = 0.0)
            }
            Lens.LEFT_TO_SPEND -> {
                val circle = max(totalIncome, totalSpent)
                if (circle <= 0) return segments(Lens.SPLIT)
                val coveredShare = if (hasSpending) min(totalIncome, totalSpent) / totalSpent / circle else 0.0
                categorySlices { (spent[it] ?: 0.0) * coveredShare } + leftoverSlices(
                    remaining = max(0.0, totalIncome - totalSpent) / circle,
                    overspent = max(0.0, totalSpent - totalIncome) / circle
                )
            }
        }
    }

    fun plan(lens: Lens): List<Slice> {
        val total = totalIncome
        val incomeShare: (BudgetCategory) -> Double = { if (total > 0) (income[it] ?: 0.0) / total else 0.0 }
        return when (lens) {
            Lens.SPLIT -> categorySlices(incomeShare) + leftoverSlices(remaining = 0.0, overspent = 0.0)
            Lens.LEFT_TO_SPEND -> {
                val circle = max(totalIncome, totalSpent)
                if (circle <= 0) return plan(Lens.SPLIT)
                val scale = min(totalIncome, totalSpent) / circle
                categorySlices { incomeShare(it) * scale } + leftoverSlices(
                    remaining = if (totalIncome > totalSpent) 1 - scale else 0.0,
                    overspent = if (totalSpent > totalIncome) 1 - scale else 0.0
                )
            }
        }
    }

    fun centerShare(lens: Lens): Double? {
        if (totalIncome <= 0) return null
        return when (lens) {
            Lens.SPLIT -> totalSpent / totalIncome
            Lens.LEFT_TO_SPEND -> abs(totalIncome - totalSpent) / totalIncome
        }
    }

    private fun categorySlices(share: (BudgetCategory) -> Double): List<Slice> =
        BudgetCategory.entries.map { Slice(SliceKind.Category(it), share(it)) }

    private fun leftoverSlices(remaining: Double, overspent: Double): List<Slice> =
        listOf(Slice(SliceKind.Remaining, remaining), Slice(SliceKind.Overspent, overspent))
}

data class DailySpend(val date: Instant, val amounts: Map<BudgetCategory, Double>) {
    val id: Instant get() = date
    val total: Double get() = amounts.values.sum()
}

data class CategorySlice(val category: BudgetCategory, val amount: Double, val share: Double) {
    val percent: Int get() = (share * 100).roundToInt()

    companion object {
        fun slices(days: List<DailySpend>): List<CategorySlice> {
            val amounts = BudgetCategory.entries.map { category -> category to days.sumOf { it.amounts[category] ?: 0.0 } }
            val total = amounts.sumOf { it.second }
            return amounts
                .filter { it.second > 0 }
                .map { (category, amount) -> CategorySlice(category, amount, amount / total) }
        }
    }
}

/** Expenses grouped by day for the daily spending chart. */
class DailySpending(
    month: Month,
    now: Instant = Instant.now(),
    private val calendar: TrenteCalendar = TrenteCalendar.current
) {
    val days: List<DailySpend>
    val monthStartDay: Instant = calendar.startOfDay(month.startDate)
    val monthEndDay: Instant = calendar.startOfDay(month.endDate(calendar))
    val today: Instant? = if (calendar.isSame(now, month.startDate, app.trente.core.model.DateGranularity.MONTH)) calendar.startOfDay(now) else null

    init {
        val amountsByDay = mutableMapOf<Instant, MutableMap<BudgetCategory, Int>>()
        for (group in month.transactionGroups) {
            if (group.type != TransactionType.EXPENSE) continue
            val day = calendar.startOfDay(group.addedDate)
            for (entry in group.entries) {
                if (entry.amountCents >= 0) continue
                val dayAmounts = amountsByDay.getOrPut(day) { mutableMapOf() }
                dayAmounts[entry.category] = (dayAmounts[entry.category] ?: 0) + abs(entry.amountCents)
            }
        }
        days = amountsByDay
            .filter { (day, _) -> day >= monthStartDay && day <= monthEndDay }
            .map { (day, amounts) -> DailySpend(day, amounts.mapValues { it.value / 100.0 }) }
            .sortedBy { it.date }
    }

    val daysInMonth: Int get() = calendar.daysBetween(monthStartDay, monthEndDay).toInt() + 1

    /** The last seven days of the month so far, clamped to its start. */
    val defaultWeekStart: Instant
        get() {
            val anchor = today ?: monthEndDay
            val candidate = calendar.plusDays(anchor, (1 - WEEK_LENGTH_IN_DAYS).toLong())
            return maxOf(candidate, monthStartDay)
        }

    fun day(on: Instant): DailySpend? = days.firstOrNull { calendar.isSameDay(it.date, on) }

    fun weekWindow(at: Instant): ClosedRange<Instant> {
        val start = calendar.startOfDay(at)
        return start..calendar.plusDays(start, (WEEK_LENGTH_IN_DAYS - 1).toLong())
    }

    fun days(inWindowAt: Instant): List<DailySpend> {
        val window = weekWindow(inWindowAt)
        return days.filter { it.date in window }
    }

    fun maxTotal(inWindowAt: Instant?): Double {
        val windowDays = inWindowAt?.let { days(it) } ?: days
        return windowDays.maxOfOrNull { it.total } ?: 0.0
    }

    companion object {
        const val WEEK_LENGTH_IN_DAYS = 7
    }
}

/** Splitting an amount across the categories, in whole units, with the last cents handed out at the end. */
class RepartitionSplit(var amountToSplit: Int, values: Map<BudgetCategory, Int>) {
    private val mutableValues: MutableMap<BudgetCategory, Int> = values.toMutableMap()

    val values: Map<BudgetCategory, Int> get() = mutableValues

    val remaining: Int get() = amountToSplit - values.values.sum()

    fun amount(category: BudgetCategory): Int = values[category] ?: 0

    fun decrease(category: BudgetCategory) {
        mutableValues[category] = decreasedValue(amount(category))
    }

    fun increase(category: BudgetCategory) {
        mutableValues[category] = increasedValue(amount(category), remaining)
    }

    fun stepUp(category: BudgetCategory) {
        mutableValues[category] = steppedUpValue(amount(category), amountToSplit, remaining)
    }

    fun stepDown(category: BudgetCategory) {
        mutableValues[category] = steppedDownValue(amount(category), amountToSplit)
    }

    fun set(category: BudgetCategory, proposedValue: Int) {
        mutableValues[category] = clampedValue(proposedValue, amount(category), remaining)
    }

    fun value(forDragFraction: Double, of: BudgetCategory): Int =
        dragValue(forDragFraction, amountToSplit, maxValue = amount(of) + remaining)

    override fun equals(other: Any?): Boolean =
        other is RepartitionSplit && other.amountToSplit == amountToSplit && other.values == values

    override fun hashCode(): Int = 31 * amountToSplit + values.hashCode()

    override fun toString(): String = "RepartitionSplit($amountToSplit, $values)"

    companion object {
        const val ADJUSTMENT_STEP_COUNT = 20

        fun decreasedValue(currentValue: Int): Int {
            val amountToDecrease = min(100, if (currentValue % 100 == 0) 100 else currentValue % 100)
            return max(0, currentValue - amountToDecrease)
        }

        fun increasedValue(currentValue: Int, remaining: Int): Int {
            val amountToIncrease = min(100, remaining)
            return min(currentValue + amountToIncrease, currentValue + remaining)
        }

        fun clampedValue(proposedValue: Int, currentValue: Int, remaining: Int): Int {
            val clampedNewValue = min(proposedValue, currentValue + remaining)
            val roundedValue = (clampedNewValue / 100) * 100
            return min(roundedValue, currentValue + remaining)
        }

        fun dragValue(fraction: Double, total: Int, maxValue: Int): Int {
            val clampedFraction = min(max(0.0, fraction), 1.0)
            val rawNewValue = round(clampedFraction * total).toInt()
            val roundedNewValue = (rawNewValue / 100) * 100
            return min(roundedNewValue, maxValue)
        }

        fun steppedUpValue(currentValue: Int, total: Int, remaining: Int): Int {
            val nextStepValue = adjustmentStepValues(total).firstOrNull { it > currentValue } ?: currentValue
            return min(nextStepValue, currentValue + remaining)
        }

        fun steppedDownValue(currentValue: Int, total: Int): Int =
            adjustmentStepValues(total).lastOrNull { it < currentValue } ?: 0

        private fun adjustmentStepValues(total: Int): List<Int> = (0..ADJUSTMENT_STEP_COUNT).map { step ->
            if (step >= ADJUSTMENT_STEP_COUNT) return@map total
            val exactValue = total * step / ADJUSTMENT_STEP_COUNT
            min((exactValue + 50) / 100 * 100, total)
        }
    }
}

/** Lengths of stacked bars following their weights, with a minimum so tiny slices stay visible. */
object ProportionalLayout {
    fun lengths(weights: List<Double>, availableLength: Double, minimumLength: Double = 0.0): List<Double> {
        val totalWeight = weights.sum()
        if (totalWeight <= 0) return weights.map { 0.0 }
        val weightedLengths = weights.map { availableLength * it / totalWeight }
        val isRaised = weightedLengths.map { it < minimumLength }
        val raisedCount = isRaised.count { it }
        val otherWeight = weights.zip(isRaised).fold(0.0) { total, (weight, raised) -> if (raised) total else total + weight }
        if (raisedCount == 0 || otherWeight <= 0) return weightedLengths

        val otherLength = max(availableLength - minimumLength * raisedCount, 0.0)
        return weights.zip(isRaised).map { (weight, raised) -> if (raised) minimumLength else otherLength * weight / otherWeight }
    }
}
